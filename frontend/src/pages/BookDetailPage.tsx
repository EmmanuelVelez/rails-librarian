import { useState } from "react";
import { Link, useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, Pencil, Trash2, BookOpen } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { useBook, useDeleteBook } from "@/lib/hooks/use-books";
import { useBorrowBook } from "@/lib/hooks/use-borrowings";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

export default function BookDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const isLibrarian = user?.role === "librarian";
  const isMember = user?.role === "member";

  const { data: book, isLoading, isError } = useBook(Number(id));
  const deleteBookMutation = useDeleteBook();
  const borrowBookMutation = useBorrowBook();
  const [showDelete, setShowDelete] = useState(false);
  const [borrowError, setBorrowError] = useState("");

  const handleDelete = () => {
    if (!book) return;
    deleteBookMutation.mutate(book.id, {
      onSuccess: () => navigate("/books"),
    });
  };

  const handleBorrow = () => {
    if (!book) return;
    setBorrowError("");
    borrowBookMutation.mutate(book.id, {
      onError: (err: unknown) => {
        const axiosErr = err as { response?: { data?: { status?: { message?: string } } } };
        setBorrowError(
          axiosErr.response?.data?.status?.message ?? "Failed to borrow book."
        );
      },
    });
  };

  if (isLoading) {
    return (
      <div className="py-12 text-center text-muted-foreground">
        Loading book...
      </div>
    );
  }

  if (isError || !book) {
    return (
      <div className="space-y-4 py-12 text-center">
        <p className="text-muted-foreground">Book not found.</p>
        <Button variant="outline" asChild>
          <Link to="/books">
            <ArrowLeft className="h-4 w-4" />
            Back to Books
          </Link>
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <Button variant="ghost" size="sm" asChild className="-ml-2">
          <Link to="/books">
            <ArrowLeft className="h-4 w-4" />
            Back to Books
          </Link>
        </Button>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-start justify-between">
          <div className="space-y-1">
            <CardTitle className="text-2xl">{book.title}</CardTitle>
            <p className="text-muted-foreground">by {book.author}</p>
          </div>
          {isLibrarian && (
            <div className="flex items-center gap-2">
              <Button variant="outline" size="sm" asChild>
                <Link to={`/books/${book.id}/edit`}>
                  <Pencil className="h-4 w-4" />
                  Edit
                </Link>
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={() => setShowDelete(true)}
              >
                <Trash2 className="h-4 w-4" />
                Delete
              </Button>
            </div>
          )}
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex flex-wrap gap-2">
            <Badge variant="secondary">{book.genre}</Badge>
          </div>

          <Separator />

          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <p className="text-sm font-medium text-muted-foreground">ISBN</p>
              <p className="font-mono">{book.isbn}</p>
            </div>
            <div>
              <p className="text-sm font-medium text-muted-foreground">
                Availability
              </p>
              <p>
                <span
                  className={
                    book.available_copies > 0
                      ? "font-semibold text-green-600 dark:text-green-400"
                      : "font-semibold text-red-600 dark:text-red-400"
                  }
                >
                  {book.available_copies} available
                </span>{" "}
                <span className="text-muted-foreground">
                  of {book.total_copies} total
                </span>
              </p>
            </div>
            <div>
              <p className="text-sm font-medium text-muted-foreground">
                Added
              </p>
              <p>{new Date(book.created_at).toLocaleDateString()}</p>
            </div>
          </div>

          {isMember && (
            <div className="space-y-2 pt-2">
              {borrowError && (
                <div className="rounded-md border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive">
                  {borrowError}
                </div>
              )}
              {borrowBookMutation.isSuccess ? (
                <div className="rounded-md border border-green-500/50 bg-green-500/10 p-3 text-sm text-green-700 dark:text-green-400">
                  Book borrowed successfully! Due in 14 days.
                </div>
              ) : (
                <Button
                  onClick={handleBorrow}
                  disabled={book.available_copies === 0 || borrowBookMutation.isPending}
                  className="w-full sm:w-auto"
                >
                  <BookOpen className="h-4 w-4" />
                  {borrowBookMutation.isPending
                    ? "Borrowing..."
                    : book.available_copies === 0
                      ? "No Copies Available"
                      : "Borrow This Book"}
                </Button>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      <Dialog open={showDelete} onOpenChange={setShowDelete}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Book</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &ldquo;{book.title}&rdquo;? This
              action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDelete(false)}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={deleteBookMutation.isPending}
            >
              {deleteBookMutation.isPending ? "Deleting..." : "Delete"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
