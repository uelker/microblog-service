package uelker.microblog.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import uelker.microblog.model.Status;

import java.time.LocalDateTime;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ResponsePostDto(
        String id,
        String title,
        String content,
        Status status,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
