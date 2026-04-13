import apiClient from "./api-client";
import type { Book, BookFormData } from "@/types/book";
import type { PaginationMeta } from "@/components/ui/pagination";

interface ApiResponse<T> {
  status: { code: number; message: string };
  data: T;
}

interface PaginatedApiResponse<T> extends ApiResponse<T> {
  pagination: PaginationMeta;
}

export interface PaginatedResult<T> {
  data: T[];
  pagination: PaginationMeta;
}

export const getBooks = async (page = 1, perPage = 10, q?: string): Promise<PaginatedResult<Book>> => {
  const params: Record<string, string | number> = { page, per_page: perPage };
  if (q) params.q = q;
  const response = await apiClient.get<PaginatedApiResponse<Book[]>>("/api/v1/books", { params });
  return { data: response.data.data, pagination: response.data.pagination };
};

export const getBook = async (id: number): Promise<Book> => {
  const response = await apiClient.get<ApiResponse<Book>>(`/api/v1/books/${id}`);
  return response.data.data;
};

export const createBook = async (data: BookFormData): Promise<Book> => {
  const response = await apiClient.post<ApiResponse<Book>>("/api/v1/books", {
    book: data,
  });
  return response.data.data;
};

export const updateBook = async (
  id: number,
  data: Partial<BookFormData>
): Promise<Book> => {
  const response = await apiClient.patch<ApiResponse<Book>>(`/api/v1/books/${id}`, {
    book: data,
  });
  return response.data.data;
};

export const deleteBook = async (id: number): Promise<void> => {
  await apiClient.delete(`/api/v1/books/${id}`);
};
