#' Create Conda Environment for Walking
#'
#' @param envname environment name
#' @param ... additional arguments to pass to [reticulate::conda_create()]
#'
#' @return Output of [reticulate::conda_create]
#' @export
conda_create_walking_env = function(envname = "stepcount",
                                    ...) {
  reticulate::conda_create(envname = envname, ...)
}
