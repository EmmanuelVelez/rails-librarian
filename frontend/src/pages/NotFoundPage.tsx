import { Link } from "react-router-dom";
import { FileQuestion } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function NotFoundPage() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center text-center">
      <FileQuestion className="h-16 w-16 text-muted-foreground/50" />
      <h1 className="mt-6 text-7xl font-bold tracking-tighter text-foreground">
        404
      </h1>
      <p className="mt-2 text-lg text-muted-foreground">
        The page you're looking for doesn't exist.
      </p>
      <div className="mt-8 flex gap-3">
        <Button asChild variant="outline">
          <Link to="/dashboard">Dashboard</Link>
        </Button>
        <Button asChild>
          <Link to="/books">Browse Books</Link>
        </Button>
      </div>
    </div>
  );
}
