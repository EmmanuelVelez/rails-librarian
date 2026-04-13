import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Plus, Pencil, Trash2, Search } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { useBooks, useDeleteBook } from "@/lib/hooks/use-books";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Pagination } from "@/components/ui/pagination";
import type { Book } from "@/types/book";

export default function BooksPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const isLibrarian = user?.role === "librarian";

  const [searchQuery, setSearchQuery] = useState("");
  const [page, setPage] = useState(1);
  const [deleteTarget, setDeleteTarget] = useState<Book | null>(null);

  const booksQuery = useBooks(page, 10, searchQuery || undefined);
  const deleteBookMutation = useDeleteBook();

  const isSearching = searchQuery.length > 0;
  const books = booksQuery.data?.data ?? [];
  const paginationMeta = booksQuery.data?.pagination;
  const isLoading = booksQuery.isLoading;

  const handleDelete = () => {
    if (!deleteTarget) return;
    deleteBookMutation.mutate(deleteTarget.id, {
      onSuccess: () => setDeleteTarget(null),
    });
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold tracking-tight">Books</h1>
        {isLibrarian && (
          <Button asChild>
            <Link to="/books/new">
              <Plus className="h-4 w-4" />
              Add Book
            </Link>
          </Button>
        )}
      </div>

      <div className="relative max-w-sm">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          placeholder="Search by title, author, or genre..."
          value={searchQuery}
          onChange={(e) => {
            setSearchQuery(e.target.value);
            setPage(1);
          }}
          className="pl-9"
        />
      </div>

      {isLoading ? (
        <div className="py-12 text-center text-muted-foreground">Loading books...</div>
      ) : books.length === 0 ? (
        <div className="py-12 text-center text-muted-foreground">
          {isSearching ? "No books match your search." : "No books in the library yet."}
        </div>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Title</TableHead>
              <TableHead>Author</TableHead>
              <TableHead>Genre</TableHead>
              <TableHead>ISBN</TableHead>
              <TableHead>Availability</TableHead>
              {isLibrarian && <TableHead className="w-[100px]">Actions</TableHead>}
            </TableRow>
          </TableHeader>
          <TableBody>
            {books.map((book) => (
              <TableRow
                key={book.id}
                className="cursor-pointer"
                onClick={() => navigate(`/books/${book.id}`)}
              >
                <TableCell className="font-medium">{book.title}</TableCell>
                <TableCell>{book.author}</TableCell>
                <TableCell>
                  <Badge variant="secondary">{book.genre}</Badge>
                </TableCell>
                <TableCell className="font-mono text-xs">{book.isbn}</TableCell>
                <TableCell>
                  <span
                    className={
                      book.available_copies > 0
                        ? "text-green-600 dark:text-green-400"
                        : "text-red-600 dark:text-red-400"
                    }
                  >
                    {book.available_copies}
                  </span>
                  <span className="text-muted-foreground">
                    {" "}/ {book.total_copies}
                  </span>
                </TableCell>
                {isLibrarian && (
                  <TableCell>
                    <div className="flex items-center gap-1">
                      <Button
                        variant="ghost"
                        size="icon-xs"
                        onClick={(e) => {
                          e.stopPropagation();
                          navigate(`/books/${book.id}/edit`);
                        }}
                        title="Edit"
                      >
                        <Pencil />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon-xs"
                        onClick={(e) => {
                          e.stopPropagation();
                          setDeleteTarget(book);
                        }}
                        title="Delete"
                      >
                        <Trash2 />
                      </Button>
                    </div>
                  </TableCell>
                )}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}

      {paginationMeta && (
        <Pagination pagination={paginationMeta} onPageChange={setPage} />
      )}

      <Dialog open={!!deleteTarget} onOpenChange={() => setDeleteTarget(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Book</DialogTitle>
            <DialogDescription>
              Are you sure you want to delete &ldquo;{deleteTarget?.title}&rdquo;? This
              action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteTarget(null)}>
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
