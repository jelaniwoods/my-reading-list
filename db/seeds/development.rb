require "bigdecimal"
require "date"
require "time"

Book.find_or_create_by!(title: "The Left Hand of Darkness", author: "Ursula K. Le Guin", note: "Recommended by the book club.", finished: true)

Book.find_or_create_by!(title: "Beloved", author: "Toni Morrison", finished: false)

Book.find_or_create_by!(title: "Project Hail Mary", author: "Andy Weir", note: "Borrowed copy; return by the end of the month.", finished: false)
