import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../services/activity_service.dart';
import '../services/category_classifier.dart';
import '../theme/app_theme.dart';
import '../widgets/labeled_field.dart';

/// Image choisie par l'utilisateur.
class PickedImage {
  const PickedImage(this.bytes, this.mimeType);

  final Uint8List bytes;
  final String mimeType;

  String get dataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';
}

/// Ouvre la galerie et renvoie l'image choisie, réduite pour tenir
/// dans un document Firestore. `null` si l'utilisateur annule.
Future<PickedImage?> pickImageFromGallery() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1000,
    maxHeight: 1000,
    imageQuality: 75,
  );
  if (file == null) return null;
  return PickedImage(await file.readAsBytes(), file.mimeType ?? 'image/jpeg');
}

/// Formulaire d'ajout d'une activité ; la catégorie est déterminée par
/// l'IA à partir de la photo (US#6).
class AddActivityPage extends StatefulWidget {
  const AddActivityPage({super.key, this.pickImage = pickImageFromGallery});

  /// Injectable pour les tests.
  final Future<PickedImage?> Function() pickImage;

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  /// Un document Firestore est limité à 1 Mo ; le base64 ajoute ~33 %.
  static const _maxImageBytes = 700 * 1024;

  final _title = TextEditingController();
  final _location = TextEditingController();
  final _maxPeople = TextEditingController();
  final _price = TextEditingController();

  PickedImage? _image;
  String? _category;
  bool _classifying = false;

  /// Message affiché si l'analyse a échoué, `null` sinon.
  String? _classifyError;
  bool _saving = false;

  /// Incrémenté à chaque nouvelle image, pour ignorer la réponse de l'IA
  /// concernant une image qui a été remplacée entre-temps.
  int _classifyRequest = 0;

  @override
  void dispose() {
    for (final controller in [_title, _location, _maxPeople, _price]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImage() async {
    final PickedImage? image;
    try {
      image = await widget.pickImage();
    } catch (e) {
      debugPrint("Erreur lors du choix de l'image : $e");
      _showMessage("Impossible d'ouvrir l'image");
      return;
    }
    if (image == null || !mounted) return;

    if (image.bytes.length > _maxImageBytes) {
      _showMessage('Image trop lourde, choisis-en une autre');
      return;
    }
    setState(() => _image = image);
    await _classify();
  }

  Future<void> _classify() async {
    final image = _image;
    if (image == null) return;

    final request = ++_classifyRequest;
    setState(() {
      _category = null;
      _classifying = true;
      _classifyError = null;
    });

    String? category;
    String? error;
    try {
      category = await context.read<CategoryClassifier>().classify(
        image.bytes,
        image.mimeType,
      );
    } on ClassifierBusyException {
      error = "L'IA est très sollicitée, réessaie dans une minute";
    } catch (e) {
      debugPrint('Erreur de classification IA : $e');
      error = "Échec de l'analyse";
    }

    if (!mounted || request != _classifyRequest) return;
    setState(() {
      _category = category;
      _classifying = false;
      _classifyError = error;
    });
  }

  /// Retourne le message d'erreur, ou `null` si le formulaire est valide.
  String? _validate() {
    if (_image == null) return 'Ajoute une photo';
    if (_category == null) return "Attends que l'IA ait détecté la catégorie";
    if (_title.text.trim().isEmpty) return 'Le titre est obligatoire';
    if (_location.text.trim().isEmpty) return 'Le lieu est obligatoire';
    final maxPeople = int.tryParse(_maxPeople.text);
    if (maxPeople == null || maxPeople <= 0) {
      return 'Indique un nombre de personnes maximum';
    }
    if (int.tryParse(_price.text) == null) return 'Indique un prix';
    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      _showMessage(error);
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<ActivityService>().addActivity(
        Activity(
          id: '',
          title: _title.text.trim(),
          imageUrl: _image!.dataUrl,
          category: _category!,
          location: _location.text.trim(),
          price: int.parse(_price.text).toDouble(),
          maxPeople: int.parse(_maxPeople.text),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint("Erreur lors de l'ajout de l'activité : $e");
      _showMessage("Impossible d'enregistrer l'activité");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    final numbersOnly = [FilteringTextInputFormatter.digitsOnly];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leadingWidth: 64,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: IconButton(
              tooltip: 'Retour au profil',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                fixedSize: const Size(44, 44),
              ),
            ),
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Text('Nouvelle activité'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                _ImagePickerZone(image: _image, onPick: _pickImage),
                gap,
                _DetectedCategory(
                  hasImage: _image != null,
                  category: _category,
                  loading: _classifying,
                  error: _classifyError,
                  onRetry: _classify,
                ),
                gap,
                LabeledField(
                  label: 'Titre',
                  fieldKey: const Key('add-title'),
                  controller: _title,
                  hintText: 'Ex. Escalade en salle',
                  textInputAction: TextInputAction.next,
                ),
                gap,
                LabeledField(
                  label: 'Lieu',
                  fieldKey: const Key('add-location'),
                  controller: _location,
                  hintText: 'Ville ou adresse',
                  textInputAction: TextInputAction.next,
                ),
                gap,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: 'Personnes max',
                        fieldKey: const Key('add-max-people'),
                        controller: _maxPeople,
                        hintText: '12',
                        keyboardType: TextInputType.number,
                        inputFormatters: numbersOnly,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LabeledField(
                        label: 'Prix (€)',
                        fieldKey: const Key('add-price'),
                        controller: _price,
                        hintText: '25',
                        keyboardType: TextInputType.number,
                        inputFormatters: numbersOnly,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Valider'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Zone arrondie : invite à choisir une photo, puis l'affiche.
class _ImagePickerZone extends StatelessWidget {
  const _ImagePickerZone({required this.image, required this.onPick});

  final PickedImage? image;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final image = this.image;

    return SizedBox(
      height: 200,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          side: image == null
              ? const BorderSide(color: AppColors.border, width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: image == null
            ? InkWell(
                onTap: onPick,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 36,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text('Ajouter une photo', style: textTheme.titleSmall),
                    Text(
                      "L'IA en déduira la catégorie",
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(image.bytes, fit: BoxFit.cover),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: OutlinedButton.icon(
                      onPressed: onPick,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Changer'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface.withValues(
                          alpha: 0.95,
                        ),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Bloc noir non éditable affichant la catégorie trouvée par l'IA.
class _DetectedCategory extends StatelessWidget {
  const _DetectedCategory({
    required this.hasImage,
    required this.category,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final bool hasImage;
  final String? category;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final error = this.error;
    final failed = error != null;
    final String value;
    if (!hasImage) {
      value = 'Ajoute une photo';
    } else if (loading) {
      value = 'Analyse en cours…';
    } else if (failed) {
      value = error;
    } else {
      value = category!;
    }
    final detected = category != null;

    return Semantics(
      label: "Catégorie détectée par l'IA : $value, non modifiable",
      excludeSemantics: !failed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Catégorie détectée par l'IA",
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
                  Text(
                    value,
                    key: const Key('detected-category'),
                    style: textTheme.bodyLarge?.copyWith(
                      color: detected
                          ? AppColors.surface
                          : AppColors.textOnDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (failed)
              IconButton(
                tooltip: "Relancer l'analyse",
                onPressed: onRetry,
                color: AppColors.accent,
                icon: const Icon(Icons.refresh),
              )
            else
              const Icon(Icons.lock_outline, color: AppColors.textOnDark),
          ],
        ),
      ),
    );
  }
}
