import apiClient from "./api-client";
import { LoginCredentials, RegisterData, AuthResponse } from "@/types/auth";

export const loginUser = async (
  credentials: LoginCredentials
): Promise<AuthResponse> => {
  const response = await apiClient.post<AuthResponse>("/auth/login", {
    user: credentials,
  });
  return response.data;
};

export const registerUser = async (
  data: RegisterData
): Promise<AuthResponse> => {
  const response = await apiClient.post<AuthResponse>("/auth/register", {
    user: data,
  });
  return response.data;
};

export const logoutUser = async (): Promise<void> => {
  await apiClient.delete("/auth/logout");
};
