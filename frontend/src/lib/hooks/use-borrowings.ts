import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { borrowBook, returnBook, getBorrowings } from "@/lib/borrowings-api";

export function useBorrowings(page = 1, perPage = 10) {
  return useQuery({
    queryKey: ["borrowings", { page, perPage }],
    queryFn: () => getBorrowings(page, perPage),
  });
}

export function useBorrowBook() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (bookId: number) => borrowBook(bookId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["books"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      queryClient.invalidateQueries({ queryKey: ["borrowings"] });
    },
  });
}

export function useReturnBook() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (borrowingId: number) => returnBook(borrowingId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["books"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      queryClient.invalidateQueries({ queryKey: ["borrowings"] });
    },
  });
}
