import 'package:autoscan/features/offers/presentation/widgets/save_alternative_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main() {
  testWidgets('guardar alternativa permanece usable con teclado en pantalla pequeña',(tester) async {
    tester.view.physicalSize=const Size(375,667);
    tester.view.devicePixelRatio=1;
    tester.view.viewInsets=const FakeViewPadding(bottom:300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(home:Builder(builder:(context)=>Scaffold(body:TextButton(
      onPressed:()=>showDialog<String>(context:context,builder:(_)=>const SaveAlternativeDialog()),child:const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
    expect(find.byKey(const Key('confirm-save-alternative')),findsOneWidget);
    await tester.tap(find.text('Cancelar'));await tester.pumpAndSettle();
    expect(find.byType(SaveAlternativeDialog),findsNothing);
  });
}
