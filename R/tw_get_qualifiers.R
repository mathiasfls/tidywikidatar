#' Get Wikidata qualifiers for a given property of a given item
#'
#' N.B. In order to provide for consistently structured output, this function outputs either id or value for each  qualifier. The user should keep in mind that some of these come with additional detail (e.g. the unit, precision, or reference calendar).
#'
#' @param id A character vector of length 1, must start with Q, e.g. "Q254" for Wolfgang Amadeus Mozart.
#' @param p A character vector of length 1, a property. Must always start with the capital letter "P", e.g. "P31" for "instance of".
#' @param language Defaults to language set with `tw_set_language()`; if not set, "en". Use "all_available" to keep all languages. For available language values, see https://www.wikidata.org/wiki/Help:Wikimedia_language_codes/lists/all
#' @param cache Defaults to NULL. If given, it should be given either TRUE or FALSE. Typically set with `tw_enable_cache()` or `tw_disable_cache()`.
#' @param cache_connection Defaults to NULL. If NULL, and caching is enabled, `tidywikidatar` will use a local sqlite database. A custom connection to other databases can be given (see vignette `caching` for details).
#' @param overwrite_cache Logical, defaults to FALSE. If TRUE, it overwrites the table in the local sqlite database. Useful if the original Wikidata object has been updated.
#' @param disconnect_db Defaults to TRUE. If FALSE, leaves the connection to cache open.
#' @param wait In seconds, defaults to 0. Time to wait between queries to Wikidata. If data are cached locally, wait time is not applied. If you are running many queries systematically you may want to add some waiting time between queries.
#'
#' @return A data frame (a tibble) with eight columns: `id` for the input id, `property`,  `qualifier_id`, `qualifier_property`, `qualifier_value`, `rank`, `qualifier_value_type`, and `set` (to distinguish sets of data when a property is present more than once)
#' @export
#'
#' @examples
#' tw_get_qualifiers_single(id = "Q180099", p = "P26", language = "en")
tw_get_qualifiers_single <- function(id,
                                     p,
                                     language = tidywikidatar::tw_get_language(),
                                     cache = NULL,
                                     overwrite_cache = FALSE,
                                     cache_connection = NULL,
                                     disconnect_db = TRUE,
                                     wait = 0) {
  if (tw_check_cache(cache) == TRUE & overwrite_cache == FALSE) {
    db_result <- tw_get_cached_qualifiers(
      id = id,
      p = p,
      language = language
    )

    if (is.data.frame(db_result) & nrow(db_result) > 0) {
      tw_disconnect_from_cache(
        cache = cache,
        cache_connection = cache_connection,
        disconnect_db = disconnect_db
      )


      return(db_result %>%
        tibble::as_tibble())
    }
  }

  Sys.sleep(time = wait)

  w <- tryCatch(WikidataR::get_item(id = id),
    error = function(e) {
      as.character(e[[1]])
    }
  )

  if (is.character(w)) {
    usethis::ui_oops(w)
    return(tidywikidatar::tw_empty_qualifiers_df)
  } else {
    qualifiers_df <- tw_extract_qualifier(id = id, p = p, w = w)
  }

  if (tw_check_cache(cache) == TRUE) {
    tw_write_qualifiers_to_cache(
      qualifiers_df = qualifiers_df,
      language = language,
      overwrite_cache = overwrite_cache,
      cache_connection = cache_connection,
      disconnect_db = disconnect_db
    )
  }

  qualifiers_df
}




#' Get Wikidata qualifiers for a given property of a given item
#'
#' N.B. In order to provide for consistently structured output, this function outputs either id or value for each  qualifier. The user should keep in mind that some of these come with additional detail (e.g. the unit, precision, or reference calendar).
#'
#' @param id A character vector of length 1, must start with Q, e.g. "Q254" for Wolfgang Amadeus Mozart.
#' @param p A character vector of length 1, a property. Must always start with the capital letter "P", e.g. "P31" for "instance of".
#' @param language Defaults to language set with `tw_set_language()`; if not set, "en". Use "all_available" to keep all languages. For available language values, see https://www.wikidata.org/wiki/Help:Wikimedia_language_codes/lists/all
#' @param cache Defaults to NULL. If given, it should be given either TRUE or FALSE. Typically set with `tw_enable_cache()` or `tw_disable_cache()`.
#' @param cache_connection Defaults to NULL. If NULL, and caching is enabled, `tidywikidatar` will use a local sqlite database. A custom connection to other databases can be given (see vignette `caching` for details).
#' @param overwrite_cache Logical, defaults to FALSE. If TRUE, it overwrites the table in the local sqlite database. Useful if the original Wikidata object has been updated.
#' @param disconnect_db Defaults to TRUE. If FALSE, leaves the connection to cache open.
#' @param wait In seconds, defaults to 0. Time to wait between queries to Wikidata. If data are cached locally, wait time is not applied. If you are running many queries systematically you may want to add some waiting time between queries.
#'
#' @return A data frame (a tibble) with eight columns: `id` for the input id, `property`,  `qualifier_id`, `qualifier_property`, `qualifier_value`, `rank`, `qualifier_value_type`, and `set` (to distinguish sets of data when a property is present more than once)
#' @export
#'
#' @examples
#' tw_get_qualifiers(id = "Q180099", p = "P26", language = "en")
tw_get_qualifiers <- function(id,
                              p,
                              language = tidywikidatar::tw_get_language(),
                              cache = NULL,
                              overwrite_cache = FALSE,
                              cache_connection = NULL,
                              disconnect_db = TRUE,
                              wait = 0) {
  if (is.data.frame(id) == TRUE) {
    id <- id$id
  }

  unique_id <- tw_check_qid(id)

  if (length(unique_id) == 0) {
    return(tidywikidatar::tw_empty_qualifiers_df)
  }

  if (length(id) == 0 | length(p) == 0) {
    usethis::ui_stop("`tw_get_qualifiers()` requires `id` and `p` of length 1 or more.")
  } else if (length(id) == 1 & length(p) == 1) {
    return(tw_get_qualifiers_single(
      id = id,
      p = p,
      language = language,
      cache = cache,
      overwrite_cache = overwrite_cache,
      cache_connection = cache_connection,
      disconnect_db = disconnect_db,
      wait = wait
    ))
  } else if (length(id) > 1 | length(p) > 1) {
    if (overwrite_cache == TRUE | tw_check_cache(cache) == FALSE) {
      pb <- progress::progress_bar$new(total = length(id) * length(p))
      qualifiers_df <- purrr::map2_dfr(
        .x = id,
        .y = p,
        .f = function(x, y) {
          pb$tick()
          tw_get_qualifiers_single(
            id = x,
            p = y,
            language = language,
            cache = cache,
            overwrite_cache = overwrite_cache,
            cache_connection = cache_connection,
            disconnect_db = FALSE,
            wait = wait
          )
        }
      )
      tw_disconnect_from_cache(
        cache = cache,
        cache_connection = cache_connection,
        disconnect_db = disconnect_db
      )
      return(qualifiers_df)
    }

    if (overwrite_cache == FALSE & tw_check_cache(cache) == TRUE) {
      qualifiers_from_cache_df <- tw_get_cached_qualifiers(
        id = id,
        p = p,
        language = language,
        cache_connection = cache_connection,
        disconnect_db = FALSE
      )

      not_in_cache_df <- tibble::tibble(id = id, property = p) %>%
        tidyr::unite(col = "id_p", sep = "_", remove = TRUE) %>%
        dplyr::anti_join(qualifiers_from_cache_df %>%
          tidyr::unite(col = "id_p", sep = "_", remove = TRUE),
        by = "id_p"
        ) %>%
        tidyr::separate(col = .data$id_p, into = c("id", "property"))


      if (nrow(not_in_cache_df) == 0) {
        tw_disconnect_from_cache(
          cache = cache,
          cache_connection = cache_connection,
          disconnect_db = disconnect_db
        )
        return(
          dplyr::left_join(
            x = tibble::tibble(id = id),
            y = qualifiers_from_cache_df,
            by = "id"
          )
        )
      } else if (nrow(not_in_cache_df) > 0) {
        pb <- progress::progress_bar$new(total = nrow(not_in_cache_df))
        qualifiers_not_in_cache_df <- purrr::map2_dfr(
          .x = unique(not_in_cache_df$id),
          .y = unique(not_in_cache_df$property),
          .f = function(x, y) {
            pb$tick()
            tw_get_qualifiers_single(
              id = x,
              p = y,
              language = language,
              cache = cache,
              overwrite_cache = overwrite_cache,
              cache_connection = cache_connection,
              disconnect_db = FALSE,
              wait = wait
            )
          }
        )

        tw_disconnect_from_cache(
          cache = cache,
          cache_connection = cache_connection,
          disconnect_db = disconnect_db
        )

        dplyr::left_join(
          x = tibble::tibble(id = id),
          y = dplyr::bind_rows(
            qualifiers_from_cache_df,
            qualifiers_not_in_cache_df
          ),
          by = "id"
        )
      }
    }
  }
}



#' Retrieve cached qualifier
#'
#' @param id A character vector, must start with Q, e.g. "Q180099" for the anthropologist Margaret Mead. Can also be a data frame of one row, typically generated with `tw_search()` or a combination of `tw_search()` and `tw_filter_first()`.
#' @param p A character vector of length 1, a property. Must always start with the capital letter "P", e.g. "P31" for "instance of".
#' @param language Defaults to language set with `tw_set_language()`; if not set, "en". Use "all_available" to keep all languages. For available language values, see https://www.wikidata.org/wiki/Help:Wikimedia_language_codes/lists/all
#' @param cache_connection Defaults to NULL. If NULL, and caching is enabled, `tidywikidatar` will use a local sqlite database. A custom connection to other databases can be given (see vignette `caching` for details).
#' @param disconnect_db Defaults to TRUE. If FALSE, leaves the connection open.
#'
#' @return If data present in cache, returns a data frame with cached data.
#' @export
#'
#' @examples
#'
#' tw_set_cache_folder(path = tempdir())
#' tw_enable_cache()
#' tw_create_cache_folder(ask = FALSE)
#'
#' df_from_api <- tw_get_qualifiers(id = "Q180099", p = "P26", language = "en")
#'
#' df_from_cache <- tw_get_cached_qualifiers(
#'   id = "Q180099",
#'   p = "P26",
#'   language = "en"
#' )
#'
#' df_from_cache
tw_get_cached_qualifiers <- function(id,
                                     p,
                                     language = tidywikidatar::tw_get_language(),
                                     cache_connection = NULL,
                                     disconnect_db = TRUE) {
  db <- tw_connect_to_cache(
    connection = cache_connection,
    language = language
  )

  table_name <- tw_get_cache_table_name(
    type = "qualifiers",
    language = language
  )

  if (DBI::dbExistsTable(conn = db, name = table_name) == FALSE) {
    if (disconnect_db == TRUE) {
      DBI::dbDisconnect(db)
    }
    return(tidywikidatar::tw_empty_qualifiers_df)
  }

  db_result <- tryCatch(
    dplyr::tbl(src = db, table_name) %>%
      dplyr::filter(
        .data$id %in% stringr::str_to_upper(id),
        .data$property %in% stringr::str_to_upper(p)
      ),
    error = function(e) {
      logical(1L)
    }
  )
  if (isFALSE(db_result)) {
    if (disconnect_db == TRUE) {
      DBI::dbDisconnect(db)
    }
    return(tidywikidatar::tw_empty_qualifiers_df)
  }

  cached_qualifiers_df <- db_result %>%
    tibble::as_tibble()

  if (disconnect_db == TRUE) {
    DBI::dbDisconnect(db)
  }
  cached_qualifiers_df
}

#' Write qualifiers to cache
#'
#' Mostly to be used internally by `tidywikidatar`, use with caution to keep caching consistent.
#'
#' @param qualifiers_df A data frame typically generated with `tw_get_qualifiers()`.
#' @param language Defaults to language set with `tw_set_language()`; if not set, "en". Use "all_available" to keep all languages. For available language values, see https://www.wikidata.org/wiki/Help:Wikimedia_language_codes/lists/all
#' @param overwrite_cache Logical, defaults to FALSE. If TRUE, it overwrites the table in the local sqlite database. Useful if the original Wikidata object has been updated.
#' @param cache_connection Defaults to NULL. If NULL, and caching is enabled, `tidywikidatar` will use a local sqlite database. A custom connection to other databases can be given (see vignette `caching` for details).
#' @param disconnect_db Defaults to TRUE. If FALSE, leaves the connection to cache open.
#'
#' @return Silently returns the same data frame provided as input. Mostly used internally for its side effects.
#'
#' @export
#'
#' @examples
#'
#' q_df <- tw_get_qualifiers(
#'   id = "Q180099",
#'   p = "P26",
#'   language = "en",
#'   cache = FALSE
#' )
#'
#' tw_write_qualifiers_to_cache(
#'   qualifiers_df = q_df,
#'   language = "en"
#' )
tw_write_qualifiers_to_cache <- function(qualifiers_df,
                                         language = tidywikidatar::tw_get_language(),
                                         overwrite_cache = FALSE,
                                         cache_connection = NULL,
                                         disconnect_db = TRUE) {
  db <- tw_connect_to_cache(
    connection = cache_connection,
    language = language
  )

  table_name <- tw_get_cache_table_name(type = "qualifiers", language = language)

  if (DBI::dbExistsTable(conn = db, name = table_name) == FALSE) {
    # do nothing: if table does not exist, previous data cannot be there
  } else {
    if (overwrite_cache == TRUE) {
      statement <- glue::glue_sql("DELETE FROM {`table_name`} WHERE id = {id*} AND property = {p*}",
        id = unique(qualifiers_df$id),
        p = unique(qualifiers_df$property),
        table_name = table_name,
        .con = db
      )
      result <- DBI::dbExecute(
        conn = db,
        statement = statement
      )
    }
  }

  DBI::dbWriteTable(db,
    name = table_name,
    value = qualifiers_df,
    append = TRUE
  )

  if (disconnect_db == TRUE) {
    DBI::dbDisconnect(db)
  }
  invisible(qualifiers_df)
}

#' Reset qualifiers cache
#'
#' Removes the table where qualifiers are cached
#'
#' @param language Defaults to language set with `tw_set_language()`; if not set, "en". Use "all_available" to keep all languages. For available language values, see https://www.wikidata.org/wiki/Help:Wikimedia_language_codes/lists/all
#' @param cache_connection Defaults to NULL. If NULL, and caching is enabled, `tidywikidatar` will use a local sqlite database. A custom connection to other databases can be given (see vignette `caching` for details).
#' @param disconnect_db Defaults to TRUE. If FALSE, leaves the connection to cache open.
#' @param ask Logical, defaults to TRUE. If FALSE, and cache folder does not exist, it just creates it without asking (useful for non-interactive sessions).
#'
#' @return Nothing, used for its side effects.
#' @export
#'
#' @examples
#' if (interactive()) {
#'   tw_reset_qualifiers_cache()
#' }
tw_reset_qualifiers_cache <- function(language = tidywikidatar::tw_get_language(),
                                      cache_connection = NULL,
                                      disconnect_db = TRUE,
                                      ask = TRUE) {
  db <- tw_connect_to_cache(
    connection = cache_connection,
    language = language
  )

  table_name <- tw_get_cache_table_name(
    type = "qualifiers",
    language = language
  )

  if (DBI::dbExistsTable(conn = db, name = table_name) == FALSE) {
    # do nothing: if table does not exist, nothing to delete
  } else if (isFALSE(ask)) {
    DBI::dbRemoveTable(conn = db, name = table_name)
    usethis::ui_info(paste0("Qualifiers cache reset for language ", sQuote(language), " completed"))
  } else if (usethis::ui_yeah(x = paste0("Are you sure you want to remove from cache the qualifiers table for language: ", sQuote(language), "?"))) {
    DBI::dbRemoveTable(conn = db, name = table_name)
    usethis::ui_info(paste0("Qualifiers cache reset for language ", sQuote(language), " completed"))
  }

  if (disconnect_db == TRUE) {
    DBI::dbDisconnect(db)
  }
}
