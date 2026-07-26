import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(const AuthState()) {
    on<InitializeAuthEvent>(_onInitializeAuth);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<ResetPasswordEvent>(_onResetPassword);
    on<ChangePasswordEvent>(_onChangePassword);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onInitializeAuth(
    InitializeAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await repository.initialize();
    
    if (repository.isLoggedIn && repository.currentUser != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: repository.currentUser,
        isLoading: false,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      ));
    }
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final user = await repository.login(email: event.email, password: event.password);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final user = await repository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await repository.deleteAccount();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, isSuccess: false));
    try {
      await repository.resetPassword(email: event.email, newPassword: event.newPassword);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, isSuccess: false));
    try {
      await repository.changePassword(oldPassword: event.oldPassword, newPassword: event.newPassword);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, isSuccess: false));
    try {
      final updatedUser = await repository.updateProfile(
        displayName: event.displayName,
        email: event.email,
        avatarUrl: event.avatarUrl,
        financialGoal: event.financialGoal,
      );
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        user: updatedUser,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}
