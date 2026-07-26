import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAuthEvent extends AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String displayName;

  const RegisterEvent({required this.email, required this.password, required this.displayName});

  @override
  List<Object?> get props => [email, password, displayName];
}

class LogoutEvent extends AuthEvent {}

class DeleteAccountEvent extends AuthEvent {}

class ResetPasswordEvent extends AuthEvent {
  final String email;
  final String newPassword;

  const ResetPasswordEvent({required this.email, required this.newPassword});

  @override
  List<Object?> get props => [email, newPassword];
}

class ChangePasswordEvent extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const ChangePasswordEvent({required this.oldPassword, required this.newPassword});

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

class UpdateProfileEvent extends AuthEvent {
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final String? financialGoal;

  const UpdateProfileEvent({this.displayName, this.email, this.avatarUrl, this.financialGoal});

  @override
  List<Object?> get props => [displayName, email, avatarUrl, financialGoal];
}
