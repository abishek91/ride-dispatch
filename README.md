# Ride Dispatch System

A simplified ride-hailing backend system built with Ruby on Rail3. **Start the server**:
   ```bash
   bin/rails server
   ```

4. **Open the application**:HAML, featuring a real-time grid-based visualization of drivers, riders, and ride requests.

## What is this application?

This application simulates a ride-hailing service (like Uber/Lyft) with the following features:

- **Grid-based city simulation**: 100×100 grid representing a city
- **Driver management**: Add, remove, and track drivers with different statuses
- **Ride request handling**: Create ride requests with pickup and dropoff locations
- **Manual driver response system**: Drivers can accept or reject ride assignments
- **Real-time visualization**: Visual grid showing drivers, riders, targets, and dropoffs
- **Dispatch algorithm**: Intelligent driver assignment based on distance and fairness scoring
- **Trip lifecycle tracking**: Complete journey from request to pickup to dropoff

## Prerequisites

### System Requirements

- **Ruby**: 3.3.4 or later
- **Rails**: 8.0.2 or later

### macOS Setup

1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install Ruby** (using rbenv for version management):
   ```bash
   brew install rbenv ruby-build
   rbenv install 3.3.4
   rbenv global 3.3.4
   echo 'eval "$(rbenv init -)"' >> ~/.zshrc
   source ~/.zshrc
   ```

3. **Verify Ruby installation**:
   ```bash
   ruby -v
   # Should output: ruby 3.3.4
   ```

4. **Install Rails**:
   ```bash
   gem install rails -v 8.0.2
   ```

5. **Verify Rails installation**:
   ```bash
   rails -v
   # Should output: Rails 8.0.2
   ```

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/abishek91/ride-dispatch.git
   cd ride-dispatch
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Start the server**:
   ```bash
   bin/rails server
   ```

5. **Open the application**:
   Navigate to `http://localhost:3000` in your web browser

## How to Use the Application

### Basic Operations

1. **View the City Grid**: The main page displays a 100×100 grid representing the city
2. **Add Drivers**: Use the "Add Driver" form to place drivers at specific coordinates
3. **Add Riders**: Use the "Add Rider" form to create ride requests with pickup and dropoff locations
4. **Advance Time**: Click "Advance Time (Tick)" to move the simulation forward by one step
5. **Driver Responses**: When drivers are assigned rides, use Accept/Reject buttons to simulate driver decisions

### Understanding the Grid

- **D**: Driver (available or en route)
- **R**: Rider waiting for pickup
- **DR**: Driver with rider (traveling to dropoff)
- **↓**: Dropoff location
- **→**: Driver target location

### System Statistics

The interface shows real-time statistics including:
- Total drivers, riders, and ride requests
- Driver status distribution (available, on trip, offline)
- Ride request status breakdown

## How Dispatching Works

The ride dispatch system uses an intelligent algorithm to assign drivers to ride requests based on multiple factors. Here's how the process works:

### Dispatch Algorithm Overview

1. **Trigger**: Dispatching occurs when:
   - A new ride request is created
   - A driver becomes available (completes a trip)
   - Time advances (tick operation)

2. **Driver Selection Process**:
   - System finds all available drivers (status = "available")
   - Excludes drivers who have already rejected this specific request
   - Calculates a composite score for each eligible driver
   - Selects the driver with the highest score

### Scoring System

Each driver receives a score based on three components:

#### 1. Distance Score (Primary Factor)
- **Calculation**: `max(100 - manhattan_distance, 0)`
- **Purpose**: Prioritize closer drivers for faster pickup
- **Range**: 0-100 points (closer = higher score)
- **Example**: Driver 5 units away gets 95 points, driver 50 units away gets 50 points

#### 2. Fairness Score (Secondary Factor)
- **Base Score**: 100 points for all drivers
- **Ride Penalty**: -10 points per completed ride
- **Recency Bonus**: +5 points per hour since last completed ride (max 50 points)
- **New Driver Bonus**: +50 points for drivers with zero completed rides
- **Purpose**: Ensure work distribution fairness among drivers

#### 3. Final Score Calculation
```
Total Score = Distance Score + Fairness Score
```

### Assignment Process

1. **Score Calculation**: System calculates scores for all eligible drivers
2. **Best Driver Selection**: Driver with highest total score is chosen
3. **Assignment Notification**: Driver receives ride assignment for manual response
4. **Pending State**: Ride request status becomes "pending_driver_response"
5. **Driver Decision**: Driver manually accepts or rejects the assignment

### Rejection Handling

- **Rejection Tracking**: System tracks which drivers have rejected each request
- **Reprocessing**: Rejected requests automatically retry assignment with remaining drivers
- **Exclusion**: Previously rejecting drivers are excluded from future attempts for the same request
- **Failure Limit**: After 5 rejections, the request is marked as "failed"

### Distance Calculation

- **Method**: Manhattan Distance (grid-based)
- **Formula**: `|driver_x - pickup_x| + |driver_y - pickup_y|`
- **Reasoning**: Reflects grid-based movement (no diagonal travel)
- **ETA**: Distance equals travel time in ticks (1 unit = 1 tick)

### Example Scenario

**Situation**: Ride request at (50, 50) with three available drivers:

1. **Driver A** at (45, 45):
   - Distance: 10 units → Distance Score: 90
   - Completed rides: 2 → Fairness Score: 80 (100 - 20)
   - **Total Score: 170**

2. **Driver B** at (40, 40):
   - Distance: 20 units → Distance Score: 80
   - Completed rides: 0 → Fairness Score: 150 (100 + 50 new driver bonus)
   - **Total Score: 230** ← **Selected**

3. **Driver C** at (48, 48):
   - Distance: 4 units → Distance Score: 96
   - Completed rides: 8, last ride 2 hours ago → Fairness Score: 90 (100 - 80 + 10)
   - **Total Score: 186**

**Result**: Driver B is selected despite being farther away due to the new driver fairness bonus.

## System Behavior and Assumptions

### Driver Movement
- **Speed**: Drivers move 1 grid unit per tick (time step)
- **Movement Pattern**: Manhattan distance (grid-based, no diagonal movement)
- **Path**: Drivers move optimally toward their target (shortest Manhattan path)

### ETA Calculation
- **Method**: Manhattan distance calculation
- **Formula**: `|driver_x - target_x| + |driver_y - target_y|`
- **Units**: Grid units (1 unit = 1 tick of travel time)

### Driver Assignment Algorithm
- **Distance Priority**: Closer drivers are preferred
- **Fairness Scoring**: Drivers with fewer completed rides get priority
- **Availability**: Only available drivers can be assigned new rides
- **Rejection Handling**: Drivers can reject assignments, triggering reassignment

### Driver Rejection System
- **Manual Control**: Drivers manually accept or reject ride assignments
- **Rejection Limit**: Maximum 5 rejection attempts per ride request
- **Failure Handling**: Requests fail after exceeding rejection limit
- **Retry Logic**: System attempts to assign different drivers after rejections

### Grid and Coordinate System
- **Grid Size**: 100×100 (coordinates 0-99 on both axes)
- **Origin**: Top-left corner (0,0)
- **Boundaries**: Coordinates are validated to stay within grid bounds

### Trip Lifecycle
1. **Request Created**: Rider places request with pickup/dropoff locations
2. **Driver Assignment**: System finds optimal available driver
3. **Pending Response**: Driver receives assignment notification
4. **Driver Response**: Driver accepts or rejects the assignment
5. **En Route**: Driver moves toward pickup location
6. **Pickup**: Driver arrives and picks up rider
7. **In Transit**: Driver and rider move together to dropoff
8. **Completion**: Trip completes, driver becomes available

### Fairness Algorithm
- **Base Score**: 100 points per driver
- **Ride Penalty**: -10 points per completed ride
- **Recency Bonus**: +5 points per hour since last completed ride (max 50 points)
- **New Driver Bonus**: +50 points for drivers who haven't completed any rides

### Architecture

- **Models**: Driver, Rider, RideRequest (Plain Ruby Objects with ActiveModel)
- **Repositories**: In-memory data storage with repository pattern
- **Services**: RideDispatchService handles core business logic
- **Controllers**: RESTful controllers for each entity plus simulation control
- **Views**: HAML templates with minimal styling for clean visualization
