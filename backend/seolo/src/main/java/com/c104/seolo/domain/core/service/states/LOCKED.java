package com.c104.seolo.domain.core.service.states;

import com.c104.seolo.domain.core.dto.request.CoreRequest;
import com.c104.seolo.domain.core.dto.response.CoreResponse;
import com.c104.seolo.domain.core.enums.CODE;
import com.c104.seolo.domain.core.exception.CoreErrorCode;
import com.c104.seolo.domain.core.service.CodeState;
import com.c104.seolo.domain.core.service.Context;
import com.c104.seolo.domain.task.dto.TaskHistoryDto;
import com.c104.seolo.domain.task.service.TaskHistoryService;
import com.c104.seolo.global.exception.CommonException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class LOCKED implements CodeState {
    private final TaskHistoryService taskHistoryService;



    @Override
    public CoreResponse handle(Context context) {
        /*
            1. 데이터를 받은 백엔드 서버는 아래 데이터를 통해 `task_history 테이블에서 작업내역 튜플을 찾는다.
                - 사용자 ID (작업자 ID)
                - 장비 ID
            2. 해당 튜플의 작업상태가 ‘ISSUED’ 인지 검증한다.  → 작업내역DB 의 TASK_CODE가 ISSEUD이라는건 해당 작업에 대한 토큰을 발급했다는 뜻
                - 아닐 시 오류를 띄운다.
            3. 해당 튜플의 작업상태를 ‘LOCKED’로 업데이트한다.
                - 해당 튜플의 TASK_START_DATETIME 을 요청이 들어온 시간으로 업데이트한다.
            4. 필요한 처리를 한다. (로그 저장 등)
            5. 200OK 응답
        */

        CoreRequest coreRequest = context.getCoreRequest();
        // 1
        TaskHistoryDto currentTask = taskHistoryService.getCurrentTaskHistoryByMachineIdAndUserId(coreRequest.getMachineId(), context.getCCodePrincipal().getId());
        // 2
        if (currentTask.getTaskCode() != CODE.ISSUED) {
            throw new CommonException(CoreErrorCode.IS_RELLY_SAME_LOCKER);
        }
        // 3
        taskHistoryService.updateTaskCode(currentTask.getId(), CODE.LOCKED);
        taskHistoryService.updateTaskStartTimeNow(currentTask.getId());

        return CoreResponse.builder() // 3
                .httpStatus(HttpStatus.OK)
                .message("잠금동기화 성공")
                .build();
    }
}