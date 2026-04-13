import { useState, useEffect } from "react";
import { useParams, useNavigate, Link, Navigate } from "react-router-dom";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { ArrowLeft } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { useBook, useCreateBook, useUpdateBook } from "@/lib/hooks/use-books";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";

const GENRES = [
  "Fiction",
  "Dystopian",
  "Science",
  "Philosophy",
  "Science Fiction",
  "History",
  "Technology",
  "Fantasy",
  "Biography",
] as const;

const bookSchema = z.object({
  title: z.string().min(1, "Title is required"),
  author: z.string().min(1, "Author is required"),
  genre: z.string().min(1, "Genre is required"),
  isbn: z.string().min(1, "ISBN is required"),
  total_copies: z.number({ message: "Must be a number" }).int("Must be a whole number").min(1, "At least 1 copy required"),
});

type BookFormValues = z.infer<typeof bookSchema>;

export default function BookFormPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const isEdit = !!id;

  const { data: book, isLoading: bookLoading } = useBook(Number(id));
  const createMutation = useCreateBook();
  const updateMutation = useUpdateBook();
  const [apiError, setApiError] = useState("");

  const form = useForm<BookFormValues>({
    resolver: zodResolver(bookSchema),
    defaultValues: {
      title: "",
      author: "",
      genre: "",
      isbn: "",
      total_copies: 1,
    },
  });

  useEffect(() => {
    if (isEdit && book) {
      form.reset({
        title: book.title,
        author: book.author,
        genre: book.genre,
        isbn: book.isbn,
        total_copies: book.total_copies,
      });
    }
  }, [isEdit, book, form]);

  if (user?.role !== "librarian") {
    return <Navigate to="/books" replace />;
  }

  if (isEdit && bookLoading) {
    return (
      <div className="py-12 text-center text-muted-foreground">
        Loading book...
      </div>
    );
  }

  const isPending = createMutation.isPending || updateMutation.isPending;

  const onSubmit = async (values: BookFormValues) => {
    setApiError("");
    try {
      if (isEdit) {
        await updateMutation.mutateAsync({ id: Number(id), data: values });
      } else {
        await createMutation.mutateAsync(values);
      }
      navigate("/books");
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : "Something went wrong.";
      if (
        typeof err === "object" &&
        err !== null &&
        "response" in err
      ) {
        const axiosErr = err as { response?: { data?: { status?: { message?: string } } } };
        setApiError(axiosErr.response?.data?.status?.message ?? message);
      } else {
        setApiError(message);
      }
    }
  };

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

      <Card className="mx-auto max-w-lg">
        <CardHeader>
          <CardTitle className="text-2xl">
            {isEdit ? "Edit Book" : "Add New Book"}
          </CardTitle>
          <CardDescription>
            {isEdit
              ? "Update the book details below."
              : "Fill in the details to add a new book to the library."}
          </CardDescription>
        </CardHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)}>
            <CardContent className="space-y-4">
              {apiError && (
                <div className="rounded-md border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive">
                  {apiError}
                </div>
              )}
              <FormField
                control={form.control}
                name="title"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Title</FormLabel>
                    <FormControl>
                      <Input placeholder="The Great Gatsby" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="author"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Author</FormLabel>
                    <FormControl>
                      <Input placeholder="F. Scott Fitzgerald" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="genre"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Genre</FormLabel>
                    <FormControl>
                      <select
                        {...field}
                        className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-base shadow-xs transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 md:text-sm"
                      >
                        <option value="">Select a genre</option>
                        {GENRES.map((g) => (
                          <option key={g} value={g}>
                            {g}
                          </option>
                        ))}
                      </select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="isbn"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>ISBN</FormLabel>
                    <FormControl>
                      <Input placeholder="978-0743273565" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="total_copies"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Total Copies</FormLabel>
                    <FormControl>
                      <Input
                        type="number"
                        min={1}
                        {...field}
                        onChange={(e) => field.onChange(e.target.valueAsNumber)}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <div className="flex gap-3 pt-2">
                <Button type="submit" disabled={isPending} className="flex-1">
                  {isPending
                    ? isEdit
                      ? "Saving..."
                      : "Creating..."
                    : isEdit
                      ? "Save Changes"
                      : "Create Book"}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => navigate("/books")}
                  className="flex-1"
                >
                  Cancel
                </Button>
              </div>
            </CardContent>
          </form>
        </Form>
      </Card>
    </div>
  );
}
