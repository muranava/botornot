#' botornot
#'
#' Classify users/accounts in Twitter data as bots or not bots.
#'
#' @param x Object to be classified. Can be user IDs, screen names, or
#'   data frames returned by rtweet.
#' @param fast Logical indicating whether to use the fast (lighter) model. The
#'   default (fast = FALSE) method uses the most recent 100 tweets posted by
#'   users to determine the probability of bot. The fast (fast = TRUE) method
#'   only uses users-level data, which is easier to get in large quantities from
#'   Twitter's APIS but overall less accurate.
#' @return Classifications for all users expressed as probability of whether
#'   each account is a bot.
#' @export
botornot <- function(x, fast = FALSE) UseMethod("botornot")

#' @export
botornot.data.frame <- function(x, fast = FALSE) {
  ## convert factors to char if necessary
  x <- convert_factors(x)
  ## merge users and tweets data
  x <- rtweet_join(x)
  ## store screen names
  sn <- unique(x$screen_name)
  if (fast) {
    ## extract features
    x <- extract_features_ntweets(x)
    ## get model
    m <- botornot_models$ntweets
  } else {
    ## extract features
    x <- extract_features_ytweets(x)
    ## get model
    m <- botornot_models$ytweets
  }
  ## classify data
  p <- classify_data(x, m)
  ## return as tibble
  tibble::as_tibble(
    data.frame(user = sn, prob_bot = p, stringsAsFactors = FALSE),
    validate = FALSE)
}

#' @export
botornot.factor <- function(x, fast = FALSE) {
  x <- as.character(x)
  botornot(x, fast = fast)
}

#' @export
botornot.character <- function(x, fast = FALSE) {
  ## remove NA and duplicates
  x <- x[!is.na(x) & !duplicated(x)]
  ## get most recent 200 tweets
  x <- rtweet::get_timelines(x, n = 100)
  ## pass to next method
  botornot(x, fast = fast)
}
