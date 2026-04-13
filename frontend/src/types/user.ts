export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  role: "member" | "librarian";
  created_at: string;
}
