package uelker.microblog.dto;

import uelker.microblog.model.Status;

public record CreatePostDto
        (
                String title,

                String content,

                Status status) {
}
