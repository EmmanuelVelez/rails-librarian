import { BookOpen, AlertTriangle, CheckCircle } from "lucide-react";
import { useMemberDashboard } from "@/lib/hooks/use-dashboard";
import { StatsCard } from "@/components/StatsCard";
import { Badge } from "@/components/ui/badge";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString();
}

function isOverdue(dueDate: string) {
  return new Date(dueDate) < new Date(new Date().toDateString());
}

function isDueToday(dueDate: string) {
  return new Date(dueDate).toDateString() === new Date().toDateString();
}

export default function MemberDashboard() {
  const { data, isLoading, isError } = useMemberDashboard();

  if (isLoading) {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-semibold tracking-tight">My Dashboard</h1>
        <div className="grid gap-4 sm:grid-cols-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <div
              key={i}
              className="h-[120px] animate-pulse rounded-xl border bg-muted/40"
            />
          ))}
        </div>
      </div>
    );
  }

  if (isError || !data) {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-semibold tracking-tight">My Dashboard</h1>
        <div className="rounded-md border border-destructive/50 bg-destructive/10 p-4 text-sm text-destructive">
          Failed to load dashboard data. Please try again later.
        </div>
      </div>
    );
  }

  const overdueBorrowings = data.active_borrowings.filter((b) => isOverdue(b.due_date));

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold tracking-tight">My Dashboard</h1>

      <div className="grid gap-4 sm:grid-cols-3">
        <StatsCard
          title="Active Borrowings"
          value={data.active_borrowings.length}
          description="Books you currently have"
          icon={BookOpen}
        />
        <StatsCard
          title="Overdue"
          value={overdueBorrowings.length}
          description="Please return these soon"
          icon={AlertTriangle}
        />
        <StatsCard
          title="Books Returned"
          value={data.borrowing_history_count}
          description="Your reading history"
          icon={CheckCircle}
        />
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Your Active Borrowings</CardTitle>
          <CardDescription>
            Books you currently have checked out
          </CardDescription>
        </CardHeader>
        <CardContent>
          {data.active_borrowings.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted-foreground">
              You don&apos;t have any active borrowings.
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Book</TableHead>
                  <TableHead>Author</TableHead>
                  <TableHead>Borrowed</TableHead>
                  <TableHead>Due Date</TableHead>
                  <TableHead>Status</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.active_borrowings.map((b) => (
                  <TableRow key={b.id}>
                    <TableCell className="font-medium">
                      {b.book.title}
                    </TableCell>
                    <TableCell>{b.book.author}</TableCell>
                    <TableCell>{formatDate(b.borrowed_at)}</TableCell>
                    <TableCell
                      className={
                        isOverdue(b.due_date)
                          ? "font-medium text-red-600 dark:text-red-400"
                          : isDueToday(b.due_date)
                            ? "font-medium text-yellow-600 dark:text-yellow-400"
                            : ""
                      }
                    >
                      {formatDate(b.due_date)}
                    </TableCell>
                    <TableCell>
                      {isOverdue(b.due_date) ? (
                        <Badge variant="destructive">Overdue</Badge>
                      ) : isDueToday(b.due_date) ? (
                        <Badge variant="warning">Due Today</Badge>
                      ) : (
                        <Badge variant="secondary">Active</Badge>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {overdueBorrowings.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-red-600 dark:text-red-400">
              Overdue Books
            </CardTitle>
            <CardDescription>
              These books are past their due date
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Book</TableHead>
                  <TableHead>Author</TableHead>
                  <TableHead>Borrowed</TableHead>
                  <TableHead>Due Date</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {overdueBorrowings.map((b) => (
                  <TableRow key={b.id}>
                    <TableCell className="font-medium">
                      {b.book.title}
                    </TableCell>
                    <TableCell>{b.book.author}</TableCell>
                    <TableCell>{formatDate(b.borrowed_at)}</TableCell>
                    <TableCell className="font-medium text-red-600 dark:text-red-400">
                      {formatDate(b.due_date)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
