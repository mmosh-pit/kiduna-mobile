import 'package:flutter/painting.dart';

import 'enamel_tokens.dart';

abstract final class Type {
  static const _identity = 'GoudyHeavyface';
  static const _body = 'Avenir';

  static const display = TextStyle(
    fontFamily: _identity,
    fontSize: 44,
    height: 1.08,
    letterSpacing: -0.4,
    color: Enamel.text,
  );

  static const heading = TextStyle(
    fontFamily: _identity,
    fontSize: 26,
    height: 1.15,
    color: Enamel.text,
  );

  static const figure = TextStyle(
    fontFamily: _identity,
    fontSize: 20,
    height: 1.2,
    color: Enamel.cream,
  );

  static const realmName = TextStyle(
    fontFamily: _identity,
    fontSize: 13,
    height: 1.2,
    color: Enamel.text,
  );

  static const body = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.5,
    color: Enamel.text,
  );

  static const bodyQuiet = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w300,
    fontSize: 14,
    height: 1.5,
    color: Enamel.camel,
  );

  static const control = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w800,
    fontSize: 13,
    height: 1.2,
    letterSpacing: 0.3,
  );

  static const operational = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w300,
    fontSize: 11,
    height: 1.3,
    color: Enamel.camel,
  );

  static const eyebrow = TextStyle(
    fontFamily: _body,
    fontWeight: FontWeight.w800,
    fontSize: 10,
    height: 1.4,
    letterSpacing: 1.6,
    color: Enamel.camel,
  );
}
