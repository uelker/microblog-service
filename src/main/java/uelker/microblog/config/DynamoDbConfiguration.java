package uelker.microblog.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbEnhancedClient;
import software.amazon.awssdk.enhanced.dynamodb.DynamoDbTable;
import software.amazon.awssdk.enhanced.dynamodb.TableSchema;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.utils.StringUtils;
import uelker.microblog.model.Post;

@Configuration
public class DynamoDbConfiguration {
    @Value("${aws.accessKey}")
    private String accessKey;

    @Value("${aws.secretKey}")
    private String secretKey;

    @Value("${aws.region}")
    private String region;

    @Value("${aws.postTable}")
    private String postTableName;

    @Bean
    public DynamoDbEnhancedClient dynamoDbEnhancedClient() {
        return DynamoDbEnhancedClient.builder().dynamoDbClient(dynamoDbClient()).build();
    }

    private DynamoDbClient dynamoDbClient() {
        final AwsCredentialsProvider credentialsProvider = StringUtils.isNotBlank(accessKey) && StringUtils.isNotBlank(secretKey)
                ? StaticCredentialsProvider.create(AwsBasicCredentials.create(accessKey, secretKey))
                : DefaultCredentialsProvider.create();

        return DynamoDbClient.builder()
                .region(Region.of(region)).credentialsProvider(credentialsProvider).build();
    }


    @Bean
    public DynamoDbTable<Post> postTable(DynamoDbEnhancedClient dynamoClient) {
        return dynamoClient.table(this.postTableName, TableSchema.fromBean(Post.class));
    }
}
