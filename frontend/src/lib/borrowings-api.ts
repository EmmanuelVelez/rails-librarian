import apiClient from "./api-client";
import type { Borrowing } from "@/types/borrowing";
import type { PaginationMeta } from "@/components/ui/pagination";

interface ApiResponse<T> {
  status: { code: number; message: string };
  data: T;
}

interface PaginatedApiResponse<T> extends ApiResponse<T> {
  pagination: PaginationMeta;
}

export interface PaginatedBorrowingsResult {
  data: Borrowing[];
  pagination: PaginationMeta;
}

export const borrowBook = async (bookId: number): Promise<Borrowing> => {
  const response = await apiClient.post<ApiResponse<Borrowing>>(
    "/api/v1/borrowings",
    { borrowing: { book_id: bookId } }
  );
  return response.data.data;
};

export const returnBook = async (borrowingId: number): Promise<Borrowing> => {
  const response = await apiClient.put<ApiResponse<Borrowing>>(
    `/api/v1/borrowings/${borrowingId}/return`
  );
  return response.data.data;
};

export const getBorrowings = async (page = 1, perPage = 10): Promise<PaginatedBorrowingsResult> => {
  const response = await apiClient.get<PaginatedApiResponse<Borrowing[]>>(
    "/api/v1/borrowings",
    { params: { page, per_page: perPage } }
  );
  return { data: response.data.data, pagination: response.data.pagination };
};
