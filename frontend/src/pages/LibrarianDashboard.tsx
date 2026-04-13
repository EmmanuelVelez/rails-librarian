import { useState } from "react";
import {
  BookOpen,
  BookCheck,
  ArrowRightLeft,
  Clock,
  AlertTriangle,
  CalendarClock,
  RotateCcw,
} from "lucide-react";
import { useLibrarianDashboard } from "@/lib/hooks/use-dashboard";
import { useBorrowings, useReturnBook } from "@/lib/hooks/use-borrowings";
import { StatsCard } from "@/components/StatsCard";
import { Button } from "@/components/ui/button";
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
import { Pagination } from "@/components/ui/pagination";

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString();
}

function isOverdue(dueDate: string) {
  return new Date(dueDate) < new Date(new Date().toDateString());
}

function isDueToday(dueDate: string) {
  return new Date(dueDate).toDateString() === new Date().toDateString();
}

export default function LibrarianDashboard() {
  const [borrowingsPage, setBorrowingsPage] = useState(1);
  const { data, isLoading, isError } = useLibrarianDashboard();
  const { data: borrowingsData, isLoading: borrowingsLoading } = useBorrowings(borrowingsPage);
  const returnBookMutation = useReturnBook();

  const activeBorrowings = borrowingsData?.data?.filter((b) => !b.returned_at) ?? [];
  const borrowingsPagination = borrowingsData?.pagination;

  if (isLoading) {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-semibold tracking-tight">
          Librarian Dashboard
        </h1>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
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
        <h1 className="text-2xl font-semibold tracking-tight">
          Librarian Dashboard
        </h1>
        <div className="rounded-md border border-destructive/50 bg-destructive/10 p-4 text-sm text-destructive">
          Failed to load dashboard data. Please try again later.
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold tracking-tight">
        Librarian Dashboard
      </h1>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <StatsCard
          title="Total Books"
          value={data.total_books}
          description="Books in the library catalog"
          icon={BookOpen}
        />
        <StatsCard
          title="Books Available"
          value={data.books_available}
          description="Books with copies on shelf"
          icon={BookCheck}
        />
        <StatsCard
          title="Total Borrowings"
          value={data.total_borrowings}
          description="All-time borrowing records"
          icon={ArrowRightLeft}
        />
        <StatsCard
          title="Active Borrowings"
          value={data.active_borrowings}
          description="Currently checked out"
          icon={Clock}
        />
        <StatsCard
          title="Overdue"
          value={data.overdue_borrowings}
          description="Past due date, not returned"
          icon={AlertTriangle}
        />
        <StatsCard
          title="Due Today"
          value={data.due_today}
          description="Should be returned today"
          icon={CalendarClock}
        />
      </div>

      {data.overdue_members && data.overdue_members.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-red-600 dark:text-red-400">
              Members with Overdue Books
            </CardTitle>
            <CardDescription>
              These members have books past their due date
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Member</TableHead>
                  <TableHead>Book</TableHead>
                  <TableHead>Due Date</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.overdue_members.map((m, idx) => (
                  <TableRow key={idx}>
                    <TableCell className="font-medium">
                      {m.member_name}
                    </TableCell>
                    <TableCell>{m.book_title}</TableCell>
                    <TableCell className="font-medium text-red-600 dark:text-red-400">
                      {formatDate(m.due_date)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Active Borrowings</CardTitle>
          <CardDescription>
            All currently checked-out books. Mark as returned when a member brings a book back.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {borrowingsLoading ? (
            <div className="py-6 text-center text-sm text-muted-foreground">
              Loading borrowings...
            </div>
          ) : activeBorrowings.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted-foreground">
              No active borrowings.
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Member</TableHead>
                  <TableHead>Book</TableHead>
                  <TableHead>Borrowed</TableHead>
                  <TableHead>Due Date</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="w-[100px]">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {activeBorrowings.map((b) => (
                  <TableRow key={b.id}>
                    <TableCell className="font-medium">
                      {b.user.first_name} {b.user.last_name}
                    </TableCell>
                    <TableCell>{b.book.title}</TableCell>
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
                    <TableCell>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => returnBookMutation.mutate(b.id)}
                        disabled={returnBookMutation.isPending}
                      >
                        <RotateCcw className="h-3 w-3" />
                        Return
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
          {borrowingsPagination && (
            <Pagination
              pagination={borrowingsPagination}
              onPageChange={setBorrowingsPage}
            />
          )}
        </CardContent>
      </Card>
    </div>
  );
}
