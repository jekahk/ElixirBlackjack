
defmodule Deck do
  def createDeck do
  suit = ["A", 2, 3, 4, 5, 6, 7, 8, 9, 10, "J", "Q", "K"]
    deck = suit ++ suit ++ suit ++ suit
    Enum.take_random(deck, 52)
  end
end

defmodule Print do
  def printHands(holder, hand) do
    IO.write(holder)
    IO.puts(" hand:\n")
    IO.write("  ")
    Enum.map(hand, fn card ->
      IO.write(card)
      IO.write("   ")
    end)
    IO.puts("\n")
    IO.puts(CardValue.calculateValue(hand))
  end
  def printHiddenHand(first) do
    IO.puts("Dealer's hand:\n")
    IO.write("  ")
    IO.write(first)
    IO.puts("   ?\n")
  end
end

defmodule Deal do
  def dealPlayerCards(pHand, gameDeck, currentBalance, bet) do
    handValue = CardValue.calculateValue(pHand)

    cond do
      handValue == 21 ->
        {pHand, gameDeck, false}
      handValue > 21 ->
        IO.puts("\nYou bust\n")
        {pHand, gameDeck, false}

      true ->
        nextMethod = IO.gets(case length(pHand) do
          2 ->
            "\nstay (S), rise (R) or double (D)?\n> "
          _ ->
            "\nstay (S), rise (R)?\n> "
        end) |> String.trim()

        case String.upcase(nextMethod) do
          "R" ->
            {newCard, gameDeck} = Enum.split(gameDeck, 1)
            pHand = pHand ++ newCard
            IO.puts("")
            Print.printHands("Your", pHand)
            Deal.dealPlayerCards(pHand, gameDeck, currentBalance, bet)
          "D" ->
            if currentBalance < bet do
              IO.puts("Not enough balance to double!")
              Deal.dealPlayerCards(pHand, gameDeck, currentBalance, bet)
            else
              {newCard, gameDeck} = Enum.split(gameDeck, 1)
              pHand = pHand ++ newCard
              IO.puts("")
              IO.puts("You doubled")
              Print.printHands("Your", pHand)
              {pHand, gameDeck, true}
            end
          "S" ->
            IO.puts("")
            IO.puts("You stand")
            {pHand, gameDeck, false}
          _ ->
            IO.puts("")
            IO.puts("Invalid input!")
            Deal.dealPlayerCards(pHand, gameDeck, currentBalance, bet)
        end
    end
  end

  def dealDealerCards(dHand, gameDeck) do
    handValue = CardValue.calculateValue(dHand)

    cond do
      handValue <= 21 && handValue >= 17 && length(dHand) == 2 ->
        Print.printHands("\nDealer's", dHand)
        {dHand, gameDeck}
      handValue <=21 && handValue >= 17 ->
        {dHand, gameDeck}
      handValue > 21 ->
        IO.puts("\nDealer bust")
        {dHand, gameDeck}
      true ->
        {newCard, gameDeck} = Enum.split(gameDeck, 1)
        dHand = dHand ++ newCard
        Print.printHands("\nDealer's", dHand)
        Deal.dealDealerCards(dHand, gameDeck)

    end
  end
end

defmodule CardValue do

  #Calculates and returns the number value of dealt hand
  def calculateValue(list) do
    handValue = calculateValue(list, 0)

    if handValue > 21 and "A" in list do
      aceInHand = Enum.count(list, fn x -> x == "A" end)
      handValue - 10 * aceInHand
    else
      handValue
    end
  end

  defp calculateValue([], value), do: value
  defp calculateValue(["J" | rest], value), do: calculateValue(rest, value + 10)
  defp calculateValue(["Q" | rest], value), do: calculateValue(rest, value + 10)
  defp calculateValue(["K" | rest], value), do: calculateValue(rest, value + 10)
  defp calculateValue(["A" | rest], value), do: calculateValue(rest, value + 11)
  defp calculateValue([item | rest], value), do: calculateValue(rest, value + item)

end

defmodule Game do
  def main() do

    IO.puts("\n\n\n\nWelcome to Blackjack!\n\n")

    Code.require_file("SaveSystem.exs") #import Module SaveSystem with functions saves, newSave, listSaves, selectSave, deleteSave
    selectedSave = SaveSystem.saves()

    {currentBalance, bet} = Game.bet(selectedSave)



    Game.round(selectedSave, currentBalance, bet)


  end

  def bet(selectedSave) do

    Code.require_file("BetSystem.exs") #import Module BetSystm with functions loadBalance, manageBalance, placeBet
    initalBalance = BetSystem.loadBalance(selectedSave)
    IO.puts("Your balance: " <> Integer.to_string(initalBalance))
    bet = BetSystem.placeBet(initalBalance)
    BetSystem.manageBalance(selectedSave, initalBalance, -bet)
    currentBalance = initalBalance - bet
    {currentBalance, bet}

  end

  def round(selectedSave, currentBalance, bet) do
    gameDeck = Deck.createDeck()
    {dHand, gameDeck} = Enum.split(gameDeck, 2)
    {pHand, gameDeck} = Enum.split(gameDeck, 2)

    Print.printHiddenHand(dHand |> List.first())
    Print.printHands("Your", pHand)

    {pHand, gameDeck, isDoubled} = Deal.dealPlayerCards(pHand, gameDeck, currentBalance, bet)
    pHandValue = CardValue.calculateValue(pHand)

    bet = if isDoubled do
      BetSystem.manageBalance(selectedSave, currentBalance, -bet)
      bet*2
    else
      bet
    end

    {dHand, _gameDeck} = Deal.dealDealerCards(dHand, gameDeck)
    dHandValue = CardValue.calculateValue(dHand)

    win = cond do
      pHandValue > 21 ->
        IO.puts("\nHouse wins\n")
        -bet
      pHandValue < dHandValue && dHandValue <= 21 ->
        IO.puts("\nHouse wins\n")
        -bet
      pHandValue == dHandValue && pHandValue <= 21 ->
        BetSystem.manageBalance(selectedSave, currentBalance, bet)
        IO.puts("\nDraw\n")
        bet
      pHandValue == 21 && length(pHand) == 2 ->
        win = round(bet*2.5)
        BetSystem.manageBalance(selectedSave, currentBalance, win)
        IO.puts("\nBlackjack!\n")
        win
      pHandValue > dHandValue || dHandValue > 21 ->
        win = bet*2
        BetSystem.manageBalance(selectedSave, currentBalance, win)
        IO.puts("\nYou won!\n")
        win
    end

    IO.puts("Win/Lose: "<>Integer.to_string(win))
    afterBalance = BetSystem.loadBalance(selectedSave)
    IO.puts("Your balance: "<>Integer.to_string(afterBalance)<>"\n")

    if afterBalance != 0 do
      playAgain = Game.replay()

      if playAgain == true do
        {currentBalance, bet} = Game.bet(selectedSave)
        Game.round(selectedSave, currentBalance, bet)
      end
    else
      IO.puts("You are out of balance. Current save will be deleted.\n")
      SaveSystem.deleteSave(selectedSave)
    end

  end

  def replay() do
    continue = IO.gets("\nPlay another hand? Yes (Y), No (N)\n> ") |> String.trim()

    case String.upcase(continue) do
      "Y" ->
        IO.puts("")
        true
      "N" ->
        false
      _ ->
        IO.puts("")
        IO.puts("Invalid input!")
        Game.replay()
    end
  end
end

Game.main()
