export interface Book {
  id: number;
  title: string;
  author: string;
  genre: string;
  isbn: string;
  total_copies: number;
  available_copies: number;
  created_at: string;
}

export interface BookFormData {
  title: string;
  author: string;
  genre: string;
  isbn: string;
  total_copies: number;
}
