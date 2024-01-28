package uelker.microblog.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbAttribute;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbBean;
import software.amazon.awssdk.enhanced.dynamodb.mapper.annotations.DynamoDbPartitionKey;

import java.time.LocalDateTime;


@DynamoDbBean
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Post {
    private String id;
    private String title;
    private String content;
    private Status status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @DynamoDbPartitionKey
    @DynamoDbAttribute("id")
    public String getId() {
        return this.id;
    }
}
