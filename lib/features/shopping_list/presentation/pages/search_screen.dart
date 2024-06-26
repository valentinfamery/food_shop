import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_shop/config/utils/languages.dart';
import 'package:food_shop/features/shopping_list/presentation/widgets/list_tag.dart';
import 'package:food_shop/features/shopping_list/presentation/widgets/list.dart';
import 'package:food_shop/features/shopping_list/presentation/widgets/button_country_settings.dart';
import 'package:food_shop/features/shopping_list/data/models/product_floor.dart';
import 'package:food_shop/features/shopping_list/domain/repository/product_repository.dart';
import 'package:food_shop/injection_container.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

final listSearchProductProvider =
    StateProvider<SearchState>((ref) => SearchState.empty());

final buttonTagProvider = StateProvider<String>((ref) => 'Categories');

final textFieldNameProvider = StateProvider<TextEditingController>(
    (ref) => TextEditingController(text: ''));
final textFieldBrandProvider = StateProvider<TextEditingController>(
    (ref) => TextEditingController(text: ''));
final textFieldStoresProvider = StateProvider<TextEditingController>(
    (ref) => TextEditingController(text: ''));
final textFieldIngredientsProvider = StateProvider<TextEditingController>(
    (ref) => TextEditingController(text: ''));

final scanBarcodeProvider = StateProvider<String>((ref) => '');

final searchTypeProvider = StateProvider((ref) => SearchType.food);

enum SearchStateType { empty, loading, success }

class SearchState<T> {
  final SearchStateType type;
  final List<ProductFoodShop>? data;
  final Object? error;

  SearchState.empty()
      : type = SearchStateType.empty,
        data = [],
        error = null;

  SearchState.loading()
      : type = SearchStateType.loading,
        data = null,
        error = null;

  SearchState.success(this.data)
      : type = SearchStateType.success,
        error = null;
}

enum SearchType { food, petfood, beauty }

class SearchScreen extends ConsumerWidget {
  final productRepository = sl<ProductRepository>();

  SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SearchState listSearchProduct = ref.watch(listSearchProductProvider);
    final textFieldName = ref.watch(textFieldNameProvider);
    final textFieldBrand = ref.watch(textFieldBrandProvider);
    final textFieldStores = ref.watch(textFieldStoresProvider);
    final textFieldIngredients = ref.watch(textFieldIngredientsProvider);
    String buttonTag = ref.watch(buttonTagProvider);
    PnnsGroup2? pnnsGroup2 = ref.watch(selectedPnnsGroup2);
    final country = ref.watch(countryStateProvider);
    final language = ref.watch(languageProvider);
    final barcode = ref.watch(scanBarcodeProvider);

    final searchType = ref.watch(searchTypeProvider);

    final width = MediaQuery.of(context).size.width;
    final height =
        MediaQuery.of(context).size.height - kBottomNavigationBarHeight;

    return Scaffold(
      //appBar: AppBar(),
      body: SizedBox(
        width: width,
        height: height,
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: width * 0.9,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: height * 0.075,
                  ),
                  TextField(
                    controller: textFieldName,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Saisissez le Nom du Produit ',
                    ),
                  ),
                  ExpansionTile(
                    title: const Text('Autres critères'),
                    children: [
                      TextField(
                        controller: TextEditingController(text: barcode),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Saisissez le code-barres',
                        ),
                      ),
                      SizedBox(
                        height: height * 0.025,
                      ),
                      TextField(
                        controller: textFieldBrand,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Saisissez la Marque du Produit',
                        ),
                      ),
                      SizedBox(
                        height: height * 0.025,
                      ),
                      TextField(
                        controller: textFieldStores,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Saisissez le Magasin du Produit',
                        ),
                      ),
                      SizedBox(
                        height: height * 0.025,
                      ),
                      TextField(
                        controller: textFieldIngredients,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Saisissez un des ingredients du Produit',
                        ),
                      ),
                      RadioListTile<SearchType>(
                        title: const Text('Food'),
                        value: SearchType.food,
                        groupValue: searchType,
                        onChanged: (SearchType? value) {
                          ref
                              .read(searchTypeProvider.notifier)
                              .update((state) => value!);
                        },
                      ),
                      RadioListTile<SearchType>(
                        title: const Text('Pet Food'),
                        value: SearchType.petfood,
                        groupValue: searchType,
                        onChanged: (SearchType? value) {
                          ref
                              .read(searchTypeProvider.notifier)
                              .update((state) => value!);
                        },
                      ),
                      RadioListTile<SearchType>(
                        title: const Text('Beauty'),
                        value: SearchType.beauty,
                        groupValue: searchType,
                        onChanged: (SearchType? value) {
                          ref
                              .read(searchTypeProvider.notifier)
                              .update((state) => value!);
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: height * 0.025,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      searchProductByName(
                        searchType,
                        textFieldName.text,
                        pnnsGroup2,
                        ref,
                        textFieldBrand.text,
                        textFieldStores.text,
                        textFieldIngredients.text,
                        barcode,
                        country!,
                        language!,
                      );
                    },
                    child: const Text('Rechercher'),
                  ),
                  SizedBox(
                    height: height * 0.025,
                  ),
                  FilledButton(
                    onPressed: () {
                      showMyDialog(context);
                    },
                    child: Text(buttonTag),
                  ),
                  SizedBox(
                    height: height * 0.025,
                  ),
                  ElevatedButton(
                      onPressed: () => scanBarcodeNormal(ref),
                      child: const Text('Scanner un code-barre')),
                  SizedBox(
                    height: height * 0.025,
                  ),
                  SizedBox(
                    height: height * 0.5,
                    width: width,
                    child: listSearchProduct.type == SearchStateType.loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListWidget(products: listSearchProduct.data!),
                  ),
                  SizedBox(
                    height: height * 0.025,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void searchProductByName(
      SearchType searchType,
      String name,
      PnnsGroup2? pnnsGroup2,
      WidgetRef ref,
      String termBrand,
      String termStore,
      String termIngredient,
      String barcode,
      OpenFoodFactsCountry country,
      OpenFoodFactsLanguage language) async {
    ref
        .read(listSearchProductProvider.notifier)
        .update((state) => SearchState.loading());

    if (searchType == SearchType.food) {
      final listAPI = await productRepository.searchProductFood(
          name,
          pnnsGroup2,
          termBrand,
          termStore,
          termIngredient,
          barcode,
          country,
          language);
      for (var element in listAPI) {
        if (kDebugMode) {
          print(element.nameLanguages![OpenFoodFactsLanguage.ENGLISH]);
        }
      }
      ref
          .read(listSearchProductProvider.notifier)
          .update((state) => SearchState.success(listAPI));
    }
  }

  Future<void> showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return const ListTag();
      },
    );
  }

  Future<void> scanBarcodeNormal(WidgetRef ref) async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      if (kDebugMode) {
        print(barcodeScanRes);
      }
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    ref.read(scanBarcodeProvider.notifier).update((state) => barcodeScanRes);
  }
}
