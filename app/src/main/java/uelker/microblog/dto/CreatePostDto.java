package uelker.microblog.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import uelker.microblog.model.Status;

public record CreatePostDto
        (
                @NotBlank()
                String title,
                @NotBlank()
                String content,
                @NotNull
                Status status) {
}
