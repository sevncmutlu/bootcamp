import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(const AuthState()) {
    on<InitializeAuthEvent>(_onInitializeAuth);
    on<CreateProfileEvent>(_onCreateProfile);
    on<DeleteProfileEvent>(_onDeleteProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onInitializeAuth(
    InitializeAuthEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await repository.initialize();
      if (repository.isLoggedIn && repository.currentUser != null) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: repository.currentUser,
            isLoading: false,
          ),
        );
      } else {
        emit(
          state.copyWith(status: AuthStatus.unauthenticated, isLoading: false),
        );
      }
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateProfile(
    CreateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final user = await repository.createProfile(
        displayName: event.displayName,
        age: event.age,
        email: event.email,
        financialGoal: event.financialGoal,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: false,
          isSuccess: true,
        ),
      );
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteProfile(
    DeleteProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await repository.deleteProfile();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, isSuccess: false));
    try {
      final updatedUser = await repository.updateProfile(
        displayName: event.displayName,
        age: event.age,
        email: event.email,
        avatarUrl: event.avatarUrl,
        financialGoal: event.financialGoal,
      );
      emit(
        state.copyWith(isLoading: false, isSuccess: true, user: updatedUser),
      );
    } on Object catch (error) {
      emit(state.copyWith(isLoading: false, error: error.toString()));
    }
  }
}
