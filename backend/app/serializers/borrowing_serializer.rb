class BorrowingSerializer
  def initialize(borrowing)
    @borrowing = borrowing
  end

  def serializable_hash
    {
      id: @borrowing.id,
      book: BookSerializer.new(@borrowing.book).serializable_hash,
      user: {
        id: @borrowing.user_id,
        email: @borrowing.user.email,
        first_name: @borrowing.user.first_name,
        last_name: @borrowing.user.last_name
      },
      borrowed_at: @borrowing.borrowed_at,
      due_date: @borrowing.due_date,
      returned_at: @borrowing.returned_at
    }
  end
end
