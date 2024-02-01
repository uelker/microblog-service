package uelker.microblog.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import uelker.microblog.model.Status;

public record CreatePostDto
        (
                @NotBlank(message = "Title cannot be blank")
                String title,

                @NotBlank(message = "Content cannot be blank")
                String content,

                @NotNull
                Status status) {
}
