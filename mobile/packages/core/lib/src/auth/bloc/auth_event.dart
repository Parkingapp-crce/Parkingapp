import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String phone;
  final String fullName;
  final String password;
  final String role;
  final String? societyJoinCode;
  final String? societyName;
  final String? societyAddress;
  final String? societyCity;
  final String? societyState;
  final String? societyPincode;
  final double? societyLatitude;
  final double? societyLongitude;

  const AuthRegisterRequested({
    required this.email,
    required this.phone,
    required this.fullName,
    required this.password,
    this.role = 'user',
    this.societyJoinCode,
    this.societyName,
    this.societyAddress,
    this.societyCity,
    this.societyState,
    this.societyPincode,
    this.societyLatitude,
    this.societyLongitude,
  });

  @override
  List<Object?> get props => [
        email,
        phone,
        fullName,
        password,
        role,
        societyJoinCode,
        societyName,
        societyAddress,
        societyCity,
        societyState,
        societyPincode,
        societyLatitude,
        societyLongitude,
      ];
}

class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut();
}
