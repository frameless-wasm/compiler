module Parser.Util.Base (expressionParser, mixedTextParser, optionsParser, rightHandSideFunctionParser, rightHandSideValueParser, sc, indentParserRepeat, indentParser, identityParser, typeParser) where

import Control.Applicative (Alternative (many), optional, (<|>))
import Text.Megaparsec (MonadParsec (lookAhead, try), between, manyTill, sepBy, some)
import Text.Megaparsec.Char (char, digitChar, eol, letterChar, lowerChar, string, upperChar)
import Text.Megaparsec.Char.Lexer (charLiteral)
import Types

-- indentParser :: Pos  -> Parser a -> Parser a
-- indentParser position parser = do
--     _ <- indentGuard space GT position
--     parser

indentParser :: IndentationLevel -> Parser a -> Parser a
indentParser indentationLevel parser = do
  _ <- many eol -- Empty lines should not break indentation-handling
  _ <- string (replicate indentationLevel '\t')
  parser

indentParserRepeat :: IndentationLevel -> Parser a -> Parser [a]
indentParserRepeat indentationLevel parser = do
  many (indentParser indentationLevel parser)

identityParser :: Parser String
identityParser = do
  firstChar <- lowerChar
  rest <- many letterChar
  return (firstChar : rest)

typeParser :: Parser String
typeParser = do
  firstChar <- upperChar
  rest <- many letterChar
  return (firstChar : rest)

mixedTextParser :: Parser [MixedText]
mixedTextParser =
  do char '\"'
    *> (dynamicTextParser <|> staticTextParser) `manyTill` char '"'

staticTextParser :: Parser MixedText
staticTextParser = do
  text <- charLiteral `manyTill` lookAhead (string "\"" <|> string "${")
  return (StaticText text)

dynamicTextParser :: Parser MixedText
dynamicTextParser = do
  value <- string "${" *> rightHandSideValueParser <* char '}'

  return (DynamicText value)

expressionParser :: Parser a -> Parser (Expression a)
expressionParser rightHandSideParser = do
  leftHandSide <- leftHandSideParser
  operator <- operatorParser
  rightHandSide <- rightHandSideParser

  return (Expression (leftHandSide, operator, rightHandSide))

leftHandSideTupleParser :: Parser LeftHandSide
leftHandSideTupleParser = do
  tuples <- between (char '(') (char ')') (sepBy leftHandSideParser (char ',' <* sc))
  return (LeftTuple tuples)

leftHandSideVariableParser :: Parser LeftHandSide
leftHandSideVariableParser = do
  hasHole <- optional (char '_')
  case hasHole of
    Just _ -> do
      _ <- sc
      return (LeftVariable Nothing)
    Nothing -> do
      variable <- identityParser <* sc
      return (LeftVariable (Just variable))

leftHandSideTypeParser :: Parser LeftHandSide
leftHandSideTypeParser = LeftType <$> typeParser

leftHandSideParser :: Parser LeftHandSide
leftHandSideParser = (leftHandSideTupleParser <|> leftHandSideVariableParser <|> leftHandSideTypeParser) <* sc

feedOperatorParser :: Parser Operator
feedOperatorParser = do
  _ <- string "<-"
  return FeedOperator

operatorParser :: Parser Operator
operatorParser = feedOperatorParser <* sc

rightHandSideOperatorParser :: Parser RightHandSideOperator
rightHandSideOperatorParser = do
  operator <- (rightHandSideOperatorPlusParser <|> rightHandSideOperatorMinusParser <|> rightHandSideOperatorMultiplyParser <|> rightHandSideOperatorDivisionParser) <* sc
  return Plus

rightHandSideOperatorPlusParser :: Parser RightHandSideOperator
rightHandSideOperatorPlusParser = do
  _ <- char '+'
  return Plus

rightHandSideOperatorMinusParser :: Parser RightHandSideOperator
rightHandSideOperatorMinusParser = do
  _ <- char '-'
  return Minus

rightHandSideOperatorMultiplyParser :: Parser RightHandSideOperator
rightHandSideOperatorMultiplyParser = do
  _ <- char '*'
  return Multiply

rightHandSideOperatorDivisionParser :: Parser RightHandSideOperator
rightHandSideOperatorDivisionParser = do
  _ <- char '/'
  return Division

rightHandSideValueVariableParser :: Parser RightHandSideValue
rightHandSideValueVariableParser = do
  variableName <- Variable <$> identityParser `sepBy` char '.'
  hasFunctionCall <- optional (char '(')

  case hasFunctionCall of
    Just _ -> do
      -- When syntax-error inside arguments, endless loop occures
      arguments <- manyTill rightHandSideValueParser (char ')')
      return (FunctionCall variableName arguments)
    Nothing -> return variableName

rightHandSideValueTextParser :: Parser RightHandSideValue
rightHandSideValueTextParser = do MixedTextValue <$> mixedTextParser

rightHandSideValueTypeParser :: Parser RightHandSideValue
rightHandSideValueTypeParser = do RightHandSideType <$> typeParser

rightHandSideValueParser :: Parser RightHandSideValue
rightHandSideValueParser = do
  rightHandSideValue <- (rightHandSideValueTypeParser <|> rightHandSideValueNumberParser <|> rightHandSideValueTextParser <|> rightHandSideValueVariableParser) <* sc
  optionalOperator <- optional rightHandSideOperatorParser

  case optionalOperator of
    Just operator -> do
      RightHandSideOperation operator rightHandSideValue <$> rightHandSideValueParser
    Nothing -> return rightHandSideValue

rightHandSideValueNumberParser :: Parser RightHandSideValue
rightHandSideValueNumberParser = do
  value <- some digitChar
  return (Number (read value))

rightHandSideFunctionParser :: Parser RightHandSide
rightHandSideFunctionParser = do
  arguments <- (leftHandSideParser `manyTill` string "->") <* sc
  FunctionDefinition arguments <$> rightHandSideValueParser

optionsParser :: IndentationLevel -> Parser a -> Parser [a]
optionsParser indentationLevel optionValueParser = do
  hasOptions <- optional (between (char '{' *> eol) (indentParser indentationLevel (char '}')) (indentParserRepeat (indentationLevel + 1) (optionValueParser <* eol)))
  _ <- eol
  case hasOptions of
    Just options -> do
      return options
    Nothing -> return []

sc :: Parser ()
sc = do
  _ <- many (char ' ')
  return ()