defmodule BetSystem do

  def loadBalance(saveName) do
    case File.read("saves/" <> saveName <> ".save") do
      {:ok, content} ->
        String.to_integer(content)
      {:error, reason} ->
        IO.puts("Failed to read file: #{reason}")
    end

  end

  def manageBalance(saveName, balance, bet) do
    newBalance = balance + bet
    File.write("saves/" <> saveName <> ".save", Integer.to_string(newBalance))
  end

  def placeBet(balance) do
    maxBet = 600
    input = IO.gets("\nPlace a bet (Max " <> Integer.to_string(maxBet) <> "):\n> ") |> String.trim()

    case Integer.parse(input) do
      {num, ""} when num > balance ->
        IO.puts("\nNot enough balance, your balance is " <> Integer.to_string(balance) <> ".\n")
        BetSystem.placeBet(balance)
      {num, ""} when num <= maxBet ->
        String.to_integer(input)
      {_num, ""} ->
        IO.puts("\nMaximum bet is " <> Integer.to_string(maxBet) <> "!\n")
        BetSystem.placeBet(balance)
      _ ->
        IO.puts("Invalid input.")
        BetSystem.placeBet(balance)
    end
  end

end
