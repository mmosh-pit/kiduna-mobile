import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/core/enums/capacity_target.dart';
import 'package:kiduna_mobile/data/models/ki_topic.dart';
import 'package:kiduna_mobile/features/field/controllers/field_controller.dart';
import 'package:kiduna_mobile/features/field/data/field_fixtures.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  FieldController controller() =>
      container.read(fieldControllerProvider.notifier);
  FieldState state() => container.read(fieldControllerProvider);

  test('starts with the default Ki topic, inspect closed, full focus', () {
    expect(state().inspectOpen, isFalse);
    expect(state().fieldFocus, 100);
    expect(state().kiTopic, FieldFixtures.defaultKi);
    expect(state().preservedMessage, isNull);
  });

  test('toggleInspect flips inspectOpen', () {
    controller().toggleInspect();
    expect(state().inspectOpen, isTrue);
    controller().toggleInspect();
    expect(state().inspectOpen, isFalse);
  });

  test('setFieldFocus updates the focus value', () {
    controller().setFieldFocus(40);
    expect(state().fieldFocus, 40);
  });

  test('askAbout sets the Ki topic', () {
    const topic = KiTopic(title: 'Title', body: 'Body');
    controller().askAbout(topic);
    expect(state().kiTopic, topic);
  });

  test('preserveMessage trims and keeps the message, sets the ack topic', () {
    controller().preserveMessage('  hello  ');
    expect(state().preservedMessage, 'hello');
    expect(state().kiTopic, FieldFixtures.messagePreserved);
  });

  test('preserveMessage ignores blank input', () {
    controller().preserveMessage('   ');
    expect(state().preservedMessage, isNull);
  });

  test('setKiFraction clamps to the 0.25–0.34 range', () {
    controller().setKiFraction(0.5);
    expect(state().kiFraction, 0.34);
    controller().setKiFraction(0.1);
    expect(state().kiFraction, 0.25);
  });

  test('chooseAction opens the working panel and sets its topic', () {
    final action = FieldFixtures.actions.first;
    controller().chooseAction(action);
    expect(state().openActions, contains(action.id));
    expect(state().kiTopic, action.topic);
    // Opening again does not duplicate.
    controller().chooseAction(action);
    expect(state().openActions.where((id) => id == action.id).length, 1);
  });

  test('closeAction removes the working panel', () {
    controller().openActionById('shape');
    expect(state().openActions, contains('shape'));
    controller().closeAction('shape');
    expect(state().openActions, isNot(contains('shape')));
  });

  test('openCapacity and closeCapacity track per target', () {
    controller().openCapacity(CapacityTarget.realm, 'wisdom');
    controller().openCapacity(CapacityTarget.ally, 'skills');
    expect(state().realmCapacities, ['wisdom']);
    expect(state().allyCapacities, ['skills']);
    controller().closeCapacity(CapacityTarget.realm, 'wisdom');
    expect(state().realmCapacities, isEmpty);
    expect(state().allyCapacities, ['skills']);
  });

  test('createRealm enters the new Realm and closes the Form panel', () {
    controller().openActionById('realm');
    controller().createRealm(name: 'Route Plan', type: 'Project');
    expect(state().currentRealm.name, 'Route Plan');
    expect(state().currentRealm.type, 'Project');
    expect(state().openActions, isNot(contains('realm')));
    expect(state().kiTopic.title, contains('Route Plan'));
  });
}
