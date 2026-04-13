import apiClient from "./api-client";
import type { LibrarianDashboard, MemberDashboard } from "@/types/borrowing";

interface ApiResponse<T> {
  status: { code: number; message: string };
  data: T;
}

export const getLibrarianDashboard = async (): Promise<LibrarianDashboard> => {
  const response = await apiClient.get<ApiResponse<LibrarianDashboard>>(
    "/api/v1/dashboard"
  );
  return response.data.data;
};

export const getMemberDashboard = async (): Promise<MemberDashboard> => {
  const response = await apiClient.get<ApiResponse<MemberDashboard>>(
    "/api/v1/dashboard"
  );
  return response.data.data;
};
