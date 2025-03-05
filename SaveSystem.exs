defmodule SaveSystem do

  def saves() do
    option = IO.gets("\nLoad save (L), Create new save (N), Delete save (D)\n> ") |> String.trim()

    case String.upcase(option) do
      "L" ->
        SaveSystem.listSaves()
      "N" ->
        SaveSystem.newSave()
        IO.puts("\nSave created!\n")
        SaveSystem.saves()
      "D" ->
          save = SaveSystem.listSaves()
          SaveSystem.deleteSave(save)
          IO.puts("Save "<>save<>" deleted!")
          SaveSystem.saves()
      _ ->
        IO.puts("")
        IO.puts("Invalid input!")
        SaveSystem.saves()
    end
  end

  def newSave() do

    unless File.dir?("saves") do
      File.mkdir("saves")
    end

    saveName = IO.gets("\nInsert save name:\n> ") |> String.trim()
    fileName = "saves/" <> saveName <> ".save"

    if File.exists?(fileName) do
      IO.puts("Save already exist! Select different name.\n")
      SaveSystem.newSave()
    else
      File.write!(fileName, "1000")
    end

  end

  def deleteSave(saveName) do
    File.rm("saves/" <> saveName <> ".save")
  end

  def listSaves() do
    case File.ls("saves") do
      {:ok, files} ->
        saveNames =
          files
          |> Enum.filter(&String.ends_with?(&1, ".save"))
          |> Enum.map(&String.replace_suffix(&1, ".save", ""))
          |> Enum.with_index(1)

        if saveNames == [] do
          IO.puts("\nNo saves found.")
          SaveSystem.saves()
        else
          IO.puts("")
          Enum.each(saveNames, fn {name, index} -> IO.puts("#{index}: #{name}") end)
          selectSave(saveNames)
        end

      {:error, reason} ->
        IO.puts("Error reading directory: #{reason}")
    end
  end

  defp selectSave(files) do
    case IO.gets("\nSelect a file by number:\n> ") |> String.trim() |> Integer.parse() do
      {num, _} when num in 1..length(files)//1 ->
        {selected_file, _} = Enum.at(files, num - 1)
        IO.puts("\nYou selected save: #{selected_file}")
        selected_file
      _ ->
        IO.puts("Invalid selection. Try again.")
        selectSave(files)
    end
  end

end
