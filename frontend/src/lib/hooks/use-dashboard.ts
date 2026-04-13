import { useQuery } from "@tanstack/react-query";
import {
  getLibrarianDashboard,
  getMemberDashboard,
} from "@/lib/dashboard-api";

export function useLibrarianDashboard() {
  return useQuery({
    queryKey: ["dashboard", "librarian"],
    queryFn: getLibrarianDashboard,
  });
}

export function useMemberDashboard() {
  return useQuery({
    queryKey: ["dashboard", "member"],
    queryFn: getMemberDashboard,
  });
}
