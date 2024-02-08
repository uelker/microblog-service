package uelker.microblog.dto;

import uelker.microblog.model.Status;

public record UpdatePostDto(
        String title,
        String content,
        Status status
) {

}
