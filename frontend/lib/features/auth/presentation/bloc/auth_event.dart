import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAuthEvent extends AuthEvent {}

class CreateProfileEvent extends AuthEvent {
  final String displayName;
  final int age;
  final String email;
  final String? financialGoal;

  const CreateProfileEvent({
    required this.displayName,
    required this.age,
    this.email = '',
    this.financialGoal,
  });

  @override
  List<Object?> get props => [displayName, age, email, financialGoal];
}

class DeleteProfileEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  final String? displayName;
  final int? age;
  final String? email;
  final String? avatarUrl;
  final String? financialGoal;

  const UpdateProfileEvent({
    this.displayName,
    this.age,
    this.email,
    this.avatarUrl,
    this.financialGoal,
  });

  @override
  List<Object?> get props => [
    displayName,
    age,
    email,
    avatarUrl,
    financialGoal,
  ];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String? displayName;
  final String email;
  final String password;

  const RegisterEvent({
    this.displayName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [displayName, email, password];
}

class ResetPasswordEvent extends AuthEvent {
  final String email;
  final String newPassword;

  const ResetPasswordEvent({
    required this.email,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, newPassword];
}
