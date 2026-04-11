import 'package:despesas_frontend/app/session_controller.dart';
import 'package:despesas_frontend/core/ui/components/authenticated_shell_scaffold.dart';
import 'package:despesas_frontend/core/ui/components/route_back_button.dart';
import 'package:despesas_frontend/features/space_references/domain/create_space_reference_input.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_create_result.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_item.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type.dart';
import 'package:despesas_frontend/features/space_references/domain/space_reference_type_group.dart';
import 'package:despesas_frontend/features/space_references/domain/space_references_repository.dart';
import 'package:despesas_frontend/features/space_references/presentation/space_references_view_model.dart';
import 'package:flutter/material.dart';

class SpaceReferencesScreen extends StatefulWidget {
  const SpaceReferencesScreen({
    super.key,
    required this.spaceReferencesRepository,
    this.sessionController,
  });

  final SpaceReferencesRepository spaceReferencesRepository;
  final SessionController? sessionController;

  @override
  State<SpaceReferencesScreen> createState() => _SpaceReferencesScreenState();
}

class _SpaceReferencesScreenState extends State<SpaceReferencesScreen> {
  late final SpaceReferencesViewModel _viewModel;
  final _searchController = TextEditingController();
  final _createNameController = TextEditingController();
  final _createFormKey = GlobalKey<FormState>();
  SpaceReferenceTypeGroup? _selectedGroup;
  SpaceReferenceType _selectedType = SpaceReferenceType.apartamento;

  @override
  void initState() {
    super.initState();
    _viewModel = SpaceReferencesViewModel(
      repository: widget.spaceReferencesRepository,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    _createNameController.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() async {
    await _viewModel.applyFilters(
      typeGroup: _selectedGroup,
      query: _searchController.text,
    );
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    setState(() => _selectedGroup = null);
    await _viewModel.clearFilters();
  }

  Future<void> _submitCreate() async {
    if (!_createFormKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    final result = await _viewModel.createReference(
      CreateSpaceReferenceInput(
        type: _selectedType,
        name: _createNameController.text.trim(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result.isCreated) {
      _createNameController.clear();
      setState(() {
        _selectedGroup = result.reference?.typeGroup;
        _selectedType = result.reference?.type ?? _selectedType;
        _searchController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referência criada e pronta para uso.')),
      );
      return;
    }

    if (result.isDuplicateSuggestion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já existe uma referência parecida no seu espaço.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final duplicateSuggestion = _viewModel.lastCreateResult;
        final body = RefreshIndicator(
          onRefresh: _viewModel.load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use referências já existentes antes de criar novas',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reaproveite o que já existe para manter seu espaço mais organizado.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF65727B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_viewModel.selectedReference != null) ...[
                _SelectedReferenceCard(
                  reference: _viewModel.selectedReference!,
                ),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referências existentes',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Veja primeiro o que já existe no seu espaço.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF65727B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('space-references-search-field'),
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          labelText: 'Buscar pelo nome',
                          hintText: 'Ex.: Projeto Acme, Casa da Praia',
                        ),
                        onFieldSubmitted: (_) => _applyFilters(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<SpaceReferenceTypeGroup?>(
                        key: const ValueKey('space-references-group-filter'),
                        initialValue: _selectedGroup,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Grupo da referência',
                        ),
                        items: [
                          const DropdownMenuItem<SpaceReferenceTypeGroup?>(
                            value: null,
                            child: Text(
                              'Todos os grupos',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          for (final group in SpaceReferenceTypeGroup.values)
                            DropdownMenuItem<SpaceReferenceTypeGroup?>(
                              value: group,
                              child: Text(
                                group.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedGroup = value);
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            key: const ValueKey(
                              'space-references-apply-filters',
                            ),
                            onPressed: _viewModel.isLoading
                                ? null
                                : _applyFilters,
                            icon: const Icon(Icons.search),
                            label: const Text('Filtrar'),
                          ),
                          TextButton(
                            key: const ValueKey(
                              'space-references-clear-filters',
                            ),
                            onPressed: _viewModel.isLoading
                                ? null
                                : _clearFilters,
                            child: const Text('Limpar filtros'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_viewModel.isLoading) ...[
                const SizedBox(height: 120),
                const Center(child: CircularProgressIndicator()),
              ] else if (_viewModel.loadErrorMessage != null) ...[
                _StateCard(
                  title: _viewModel.isUnauthorized
                      ? 'Sessão expirada'
                      : 'Não foi possível carregar as referências.',
                  message: _viewModel.loadErrorMessage!,
                  actionLabel: 'Tentar novamente',
                  onAction: _viewModel.load,
                ),
              ] else if (_viewModel.isEmpty) ...[
                const _StateCard(
                  title: 'Nenhuma referência encontrada',
                  message:
                      'Ainda não há referências no seu espaço com esse filtro. Você pode criar a primeira logo abaixo.',
                ),
              ] else ...[
                for (final reference in _viewModel.references) ...[
                  _SpaceReferenceCard(
                    reference: reference,
                    isSelected:
                        _viewModel.selectedReference?.id == reference.id,
                    onUse: () => _viewModel.selectReference(reference),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              if (duplicateSuggestion?.isDuplicateSuggestion ?? false) ...[
                const SizedBox(height: 16),
                _DuplicateSuggestionCard(
                  result: duplicateSuggestion!,
                  onUseSuggestion: _viewModel.useSuggestedReference,
                ),
              ],
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _createFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Criar nova referência',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Se não encontrar o que precisa, crie uma nova referência.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF65727B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<SpaceReferenceType>(
                          key: const ValueKey('space-references-type-field'),
                          initialValue: _selectedType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Tipo de referência',
                            errorText: _viewModel.fieldError('type'),
                          ),
                          items: [
                            for (final type in SpaceReferenceType.values)
                              DropdownMenuItem(
                                value: type,
                                child: Text(
                                  '${type.group.label} • ${type.label}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _selectedType = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('space-references-name-field'),
                          controller: _createNameController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Nome da referência',
                            hintText: 'Ex.: Projeto Acme, Casa da Praia',
                            errorText: _viewModel.fieldError('name'),
                          ),
                          onFieldSubmitted: (_) => _submitCreate(),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) {
                              return 'Informe o nome da referência.';
                            }
                            if (trimmed.length > 120) {
                              return 'Use no máximo 120 caracteres.';
                            }
                            return null;
                          },
                        ),
                        if (_viewModel.submitErrorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _viewModel.submitErrorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const ValueKey('space-references-submit-button'),
                          onPressed: _viewModel.isSubmitting
                              ? null
                              : _submitCreate,
                          icon: _viewModel.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_circle_outline),
                          label: Text(
                            _viewModel.isSubmitting
                                ? 'Salvando...'
                                : 'Criar referência',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        if (widget.sessionController != null) {
          return AuthenticatedShellScaffold(
            sessionController: widget.sessionController!,
            currentLocation: '/space/references',
            title: 'Referências do seu espaço',
            fallbackRoute: '/',
            body: body,
          );
        }

        return RoutePopScope<Object?>(
          fallbackRoute: '/',
          child: Scaffold(
            appBar: AppBar(
              leading: const RouteBackButton(fallbackRoute: '/'),
              title: const Text('Referências do seu espaço'),
            ),
            body: SafeArea(top: false, child: body),
          ),
        );
      },
    );
  }
}

class _SelectedReferenceCard extends StatelessWidget {
  const _SelectedReferenceCard({required this.reference});

  final SpaceReferenceItem reference;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: const ValueKey('space-references-selected-reference-card'),
      color: const Color(0xFFF2F7F4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Referência em uso agora', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(reference.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(reference.typeGroup.label)),
                Chip(label: Text(reference.type.label)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceReferenceCard extends StatelessWidget {
  const _SpaceReferenceCard({
    required this.reference,
    required this.isSelected,
    required this.onUse,
  });

  final SpaceReferenceItem reference;
  final bool isSelected;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: ValueKey('space-reference-card-${reference.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reference.name,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (isSelected)
                  const Chip(
                    label: Text('Em uso'),
                    avatar: Icon(Icons.check, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(reference.typeGroup.label)),
                Chip(label: Text(reference.type.label)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isSelected ? null : onUse,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  isSelected
                      ? 'Referência selecionada'
                      : 'Usar esta referência',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuplicateSuggestionCard extends StatelessWidget {
  const _DuplicateSuggestionCard({
    required this.result,
    required this.onUseSuggestion,
  });

  final SpaceReferenceCreateResult result;
  final VoidCallback onUseSuggestion;

  @override
  Widget build(BuildContext context) {
    final suggestion = result.suggestedReference;
    if (suggestion == null) {
      return const SizedBox.shrink();
    }

    return Card(
      key: const ValueKey('space-references-duplicate-card'),
      color: const Color(0xFFFFF7E8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message ??
                  'Já existe uma referência parecida no seu espaço.',
            ),
            const SizedBox(height: 12),
            Text(
              suggestion.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(suggestion.typeGroup.label)),
                Chip(label: Text(suggestion.type.label)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('space-references-use-suggested-button'),
              onPressed: onUseSuggestion,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Usar referência encontrada'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF65727B),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
