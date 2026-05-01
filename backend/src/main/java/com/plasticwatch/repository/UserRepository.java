package com.plasticwatch.repository;

import com.plasticwatch.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    /** Returns the rank of a user by points (1-based). */
    @Query("SELECT COUNT(u) + 1 FROM User u WHERE u.points > (SELECT u2.points FROM User u2 WHERE u2.id = :userId)")
    long findRankByUserId(Long userId);
}
