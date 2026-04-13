import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  getBooks,
  getBook,
  createBook,
  updateBook,
  deleteBook,
} from "@/lib/books-api";
import type { BookFormData } from "@/types/book";

export function useBooks(page = 1, perPage = 10, query?: string) {
  return useQuery({
    queryKey: ["books", { page, perPage, query }],
    queryFn: () => getBooks(page, perPage, query),
  });
}

export function useBook(id: number) {
  return useQuery({
    queryKey: ["books", id],
    queryFn: () => getBook(id),
    enabled: !!id,
  });
}

export function useCreateBook() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: BookFormData) => createBook(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["books"] });
    },
  });
}

export function useUpdateBook() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<BookFormData> }) =>
      updateBook(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["books"] });
    },
  });
}

export function useDeleteBook() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => deleteBook(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["books"] });
    },
  });
}
