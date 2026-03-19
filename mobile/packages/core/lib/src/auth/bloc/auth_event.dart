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

  const AuthRegisterRequested({
    required this.email,
    required this.phone,
    required this.fullName,
    required this.password,
  });

  @override
  List<Object?> get props => [email, phone, fullName, password];
}

class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut();
}
