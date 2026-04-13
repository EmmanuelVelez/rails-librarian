import { useAuth } from "@/contexts/AuthContext";
import LibrarianDashboard from "@/pages/LibrarianDashboard";
import MemberDashboard from "@/pages/MemberDashboard";

export default function DashboardPage() {
  const { user } = useAuth();

  if (user?.role === "librarian") {
    return <LibrarianDashboard />;
  }

  return <MemberDashboard />;
}
