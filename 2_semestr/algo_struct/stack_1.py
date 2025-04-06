def parse_poetry_file(file_path):
    result = []
    current_title = None
    reading_text = False
    current_text = []
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if "|name_start|" in line:
                    title_part = line.split("|name_start|")[1]
                    if "|name_close|" in title_part:
                        current_title = title_part.split("|name_close|")[0].strip()
                    else:
                        current_title = title_part.strip()
                elif "|name_close|" in line and current_title is not None:
                    current_title = current_title.split("|name_close|")[0].strip()
                elif "|text_start|" in line:
                    reading_text = True
                    if line.strip() != "|text_start|":
                        current_text.append(line.split("|text_start|")[1])
                elif "|text_close|" in line and reading_text:
                    reading_text = False
                    if line.strip() != "|text_close|":
                        current_text.append(line.split("|text_close|")[0])
                    full_text = "\n".join(current_text)
                    if current_title:
                        result.append(
                            {"title": current_title, "length": len(full_text)}
                        )

                    current_title = None
                    current_text = []
                elif reading_text:
                    current_text.append(line)
        return result

    except Exception as e:
        print(f"error: {e}")
        return []


def bubble_sort(poems):
    n = len(poems)
    sorted_poems = poems.copy()
    for i in range(n):
        # если за проход не было обменов, массив отсортирован
        swapped = False
        for j in range(0, n - i - 1):
            if sorted_poems[j]["length"] > sorted_poems[j + 1]["length"]:
                sorted_poems[j], sorted_poems[j + 1] = (
                    sorted_poems[j + 1],
                    sorted_poems[j],
                )
                swapped = True
        if not swapped:
            break

    return sorted_poems


if __name__ == "__main__":
    file_path = r"2_semestr\algo_struct\poem.txt"
    poems = parse_poetry_file(file_path)
    for poem in poems:
        print(f"title: {poem['title']}, len: {poem['length']}")
    sorted_poems = bubble_sort(poems)
    print("\n================= sorted =======================:")
    for poem in sorted_poems:
        print(f"title: {poem['title']}, len: {poem['length']}")
