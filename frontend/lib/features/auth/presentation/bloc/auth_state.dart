import 'package:equatable/equatable.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [status, user, isLoading, error, isSuccess];
}
