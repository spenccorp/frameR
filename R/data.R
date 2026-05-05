#' French Party Manifesto Data for Vignette
#'
#' A dataset containing quasi-sentences from the 2022 electoral
#' manifestos of the French National Rally and Socialist Party,
#' as collected by the Comparative Manifesto Project. Used to
#' demonstrate the frameR pipeline in the package vignette.
#'
#' @format A data frame with 4240 rows and 4 variables:
#' \describe{
#'   \item{text}{Character. The quasi-sentence text in French.}
#'   \item{party}{Numeric. MARPOR party code. 31720 = National
#'     Rally, 31320 = Socialist Party.}
#'   \item{date}{Numeric. Election date in YYYYMM format. 202206
#'     corresponds to the June 2022 French legislative elections.}
#'   \item{party_name}{Character. Human-readable party name.}
#' }
#'
#' @source Comparative Manifesto Project (MARPOR).
#'   \url{https://manifesto-project.wzb.eu}
#'
#' @references
#'   Volkens, Andrea, et al. (2021). The Manifesto Data Collection.
#'   Manifesto Project (MRG/CMP/MARPOR). Version 2021b. Berlin:
#'   Wissenschaftszentrum Berlin für Sozialforschung (WZB).
"vignette_data"
