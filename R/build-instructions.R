#' Create instruction manual for a 2D mosaic or 3D model
#' 
#' Render faceted plot of instructions for 2D mosacis or 3D model objects. For mosaics, can specify the number of steps.
#' 
#' Instructions for 2D mosaics are split into sections beginning at the bottom of the image.
#' This makes it easier to follow each row when building an actual brick mosaic.
#' 
#' 3D model instructions are displayed one Level (z value) at a time. 
#' The current model level is clearly displayed, while the previous level is shows as transparent.
#'
#' @param brickr_obj brickr mosaic or 3D model object.
#' @param num_steps Number of discrete steps in instruction manual, for mosaics only.
#' @return A single plot object of steps to build brickr model or mosaic.
#' @family Resources
#' @export 
#' @examples 
#' # Import a jpeg or png
#'  demo_file <- system.file("extdata", "demo_img.jpg", 
#'                           package = "brickr", mustWork = TRUE)
#'  demo_image <- jpeg::readJPEG(demo_file)
#'  
#'  #Create a mosaic oject 
#'  \donttest{
#'  mosaic <- demo_image %>% 
#'    image_to_mosaic(img_size = 24)
#'  }
#'  
#'  #Rather than drawing the mosaic, use build_instructions() to draw instructions
#'  \donttest{
#'   mosaic %>% 
#'    build_instructions()
#'  }
#' 
#' #Change the number of steps for more detail
#' \donttest{
#'   mosaic %>% 
#'    build_instructions(num_steps = 9)
#'  }
#' 

build_instructions <- function(brickr_obj, num_steps=6) {
  in_list <- brickr_obj
  image <- in_list$Img_bricks
  type <- in_list$brickr_object
  
  #Mosaic instructions ----
  if(type == "mosaic"){
    num_steps <- min(abs(round(num_steps)), 40)
    
    rows_per_step <- ceiling((max(image$ymax)-0.5) / (num_steps+1))
    
    create_steps <- function(a, n_steps) {
      if(a < n_steps){
        image %>% 
          dplyr::group_by(brick_name) %>% 
          dplyr::filter(min(ymin) <= a*rows_per_step+(min(image$ymin)+0.5)) %>% 
          dplyr::ungroup() %>%
          dplyr::mutate(Step = paste("Step", stringr::str_pad(a, 2, pad = "0")))
      } else {
        image %>% 
          dplyr::mutate(Step = paste("Step", stringr::str_pad(a, 2, pad = "0")))
      }
    }
    
    steps_for_plot <- 1:num_steps %>% 
      purrr::map_df(create_steps, num_steps) %>% 
      dplyr::mutate(alpha = 1)
    
  } #end mosaics
  
  else if(type == "3dmodel"){
    num_steps <- length(unique(image$Level))
    
    create_steps <- function(a, n_steps) {
      image %>% 
        dplyr::filter(dplyr::between(Level, a-1, a)) %>% 
        dplyr::mutate(alpha = ifelse(Level == a, 1, 0.5)) %>% 
        dplyr::mutate(Step = paste("Step", stringr::str_pad(a, 2, pad = "0")))
      
    }
    
    steps_for_plot <- 1:num_steps %>% 
      purrr::map_df(create_steps, num_steps) 
    
  }
  
  #Plot ----
  coord_ratio <- 1
  
  steps_for_plot %>% 
    ggplot2::ggplot() +
    ggplot2::geom_rect(ggplot2::aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax,
                                    fill = Lego_color, alpha = alpha), color = "#333333") +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_alpha_identity() + 
    ggplot2::coord_fixed(ratio = coord_ratio, expand = TRUE) +
    ggplot2::facet_wrap(~Step) +
    ggplot2::theme_minimal() +
    ggplot2::theme( panel.background = ggplot2::element_rect(fill = "#7EC0EE"),
                    strip.background = ggplot2::element_rect(fill = "#F7F18D"),
                    strip.text = ggplot2::element_text(color = "#333333", face = "bold"),
                    axis.line = ggplot2::element_blank(),
                    axis.title.x = ggplot2::element_blank(),
                    axis.text.x = ggplot2::element_blank(),
                    axis.title.y = ggplot2::element_blank(),
                    axis.text.y = ggplot2::element_blank(),
                    legend.position = "none")
}
