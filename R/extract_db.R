
########################################################
# EXTRACT THE OUTPUT OF FUNCTION infer_db()
########################################################

#' Title
#'
#' @param x   blah
#' @param methods  blah
#'
#' @return  blah
#' @export
#'
#' @import broom
#' @import tidyverse
#'
#' @examples
extract_db =
  function(x, methods = NULL){
    # x is returned from infer_db()

    ########################################################
    # THE FUNCTION "extracter" GIVES A TABLE OF P-VALUES FOR DIFFERENT METHODS:
    # p_uni  = SIMPLE UNIVARIATE REGRESSION OF B ON EACH TFBM
    # p_cov  = MULTPLE REGRESSION OF B ON ALL TFBM's SIMULTANIOUSLY
    # p_tot  = SIMPLE UNIVARIATE OF B ON THE TOTAL NUMBER SITES (NOT SPECIFIC TO ONE TFBM)
    # p_par  = parametric telis, RETURNED  ONLY IF ARGUMENT 'tT_sub' IS GIVEN TO "db"
    # p_npar = nonparametric telis, RETURNED  ONLY IF ARGUMENT 'tT_sub' IS GIVEN TO "db"
    ########################################################

    # NOTE: p_tot IS JUST ONE REGRESSION (OF DIFFERENTIAL EFFECT), THE RESULT IS
    # REPLICATED FOR CONVENIENCE

    # print("CHECK THE 2 * below!!!!!")

    if(!is.null(x$telis)){
      out =
        x$telis %>%
        unlist %>%
        enframe %>%
        tidyr::separate(name, c("method", "side", "tfbm"), sep = "\\.") %>%
        unite("method", c("method", "side")) %>%
        spread(method, value) %>%
        mutate(p_par  = 2 * pmin(par_p_vals_left_tail, par_p_vals_right_tail),
               p_npar = 2 * pmin(npar_p_vals_left_tail, npar_p_vals_right_tail),
               p_uni  = x$m$B$m_uni$p.value,
               p_cov  = x$m$B$m_cov$p.value,
               p_tot  = x$m$B$m_tot$p.value)

    } else {

      out =
        tibble(tfbm = x$m$B$m_uni$term,
               p_uni  = x$m$B$m_uni$p.value,
               p_cov  = x$m$B$m_cov$p.value,
               p_tot  = x$m$B$m_tot$p.value)
    }

    if(!is.null(methods)) out = out %>% select(tfbm, methods) # possibly subset
    return(out = out)
  }
